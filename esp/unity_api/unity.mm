#import "unity.h"

static bool is_valid_pos(Vector3 v) {
    // Игровые координаты Standoff 2 в пределах ±5000
    if (v.x != v.x || v.y != v.y || v.z != v.z) return false; // NaN
    float ax = v.x < 0 ? -v.x : v.x;
    float ay = v.y < 0 ? -v.y : v.y;
    float az = v.z < 0 ? -v.z : v.z;
    return ax < 5000.0f && ay < 5000.0f && az < 5000.0f &&
           (ax > 0.001f || ay > 0.001f || az > 0.001f);
}

static bool is_valid_quat(Vector4 q) {
    float len2 = q.x*q.x + q.y*q.y + q.z*q.z + q.w*q.w;
    return len2 > 0.5f && len2 < 2.0f; // |q| ≈ 1
}

static bool is_valid_scale(Vector3 s) {
    return s.x > 0.001f && s.x < 100.0f &&
           s.y > 0.001f && s.y < 100.0f &&
           s.z > 0.001f && s.z < 100.0f;
}

static Vector3 walk_hierarchy(mach_vm_address_t matrix_list, mach_vm_address_t matrix_indices,
                              Vector3 result, int transformIndex, size_t eSize,
                              int rotOff, int posOff, int scaleOff, task_t task) {
    int max_safety = 50;
    while (transformIndex >= 0 && max_safety-- > 0) {
        mach_vm_address_t base = matrix_list + eSize * (size_t)transformIndex;
        Vector4 rot = Read<Vector4>(base + rotOff, task);
        Vector3 pos = Read<Vector3>(base + posOff, task);
        Vector3 sc  = Read<Vector3>(base + scaleOff, task);

        if (!is_valid_quat(rot) || !is_valid_scale(sc)) return Vector3{0,0,0};

        float rX = rot.x, rY = rot.y, rZ = rot.z, rW = rot.w;
        float sX = result.x * sc.x;
        float sY = result.y * sc.y;
        float sZ = result.z * sc.z;

        result.x = pos.x + sX +
            (sX * ((rY*rY*-2.0f) - (rZ*rZ*2.0f))) +
            (sY * ((rW*rZ*-2.0f) - (rY*rX*-2.0f))) +
            (sZ * ((rZ*rX*2.0f) - (rW*rY*-2.0f)));
        result.y = pos.y + sY +
            (sX * ((rX*rY*2.0f) - (rW*rZ*-2.0f))) +
            (sY * ((rZ*rZ*-2.0f) - (rX*rX*2.0f))) +
            (sZ * ((rW*rX*-2.0f) - (rZ*rY*-2.0f)));
        result.z = pos.z + sZ +
            (sX * ((rW*rY*-2.0f) - (rX*rZ*-2.0f))) +
            (sY * ((rY*rZ*2.0f) - (rW*rX*-2.0f))) +
            (sZ * ((rX*rX*-2.0f) - (rY*rY*2.0f)));

        transformIndex = Read<int>(matrix_indices + sizeof(int) * (size_t)transformIndex, task);
    }
    return is_valid_pos(result) ? result : Vector3{0,0,0};
}

static Vector3 try_get_position(mach_vm_address_t transObj, int matOff, int idxOff, task_t task) {
    mach_vm_address_t matrix = Read<mach_vm_address_t>(transObj + matOff, task);
    if (!matrix || matrix < 0x1000000) return Vector3{0,0,0};

    mach_vm_address_t matrix_list = Read<mach_vm_address_t>(matrix + 0x18, task);
    mach_vm_address_t matrix_indices = Read<mach_vm_address_t>(matrix + 0x20, task);
    if (!matrix_list || !matrix_indices) return Vector3{0,0,0};

    int index = Read<int>(transObj + idxOff, task);
    if (index < 0 || index > 65536) return Vector3{0,0,0};

    // Layout A: 40 bytes — rotation(16) + position(12) + scale(12)
    {
        size_t eSize = 40;
        int rotOff = 0, posOff = 16, scaleOff = 28;
        Vector3 result = Read<Vector3>(matrix_list + eSize * (size_t)index + posOff, task);
        int ti = Read<int>(matrix_indices + sizeof(int) * (size_t)index, task);
        if (ti < 0 && is_valid_pos(result)) return result;
        if (ti >= 0 && ti < 65536) {
            Vector3 r = walk_hierarchy(matrix_list, matrix_indices, result, ti, eSize, rotOff, posOff, scaleOff, task);
            if (is_valid_pos(r)) return r;
        }
    }

    // Layout B: 48 bytes — position(16) + rotation(16) + scale(16)
    {
        size_t eSize = 48;
        int posOff = 0, rotOff = 16, scaleOff = 32;
        Vector3 result = Read<Vector3>(matrix_list + eSize * (size_t)index + posOff, task);
        int ti = Read<int>(matrix_indices + sizeof(int) * (size_t)index, task);
        if (ti < 0 && is_valid_pos(result)) return result;
        if (ti >= 0 && ti < 65536) {
            Vector3 r = walk_hierarchy(matrix_list, matrix_indices, result, ti, eSize, rotOff, posOff, scaleOff, task);
            if (is_valid_pos(r)) return r;
        }
    }

    return Vector3{0,0,0};
}

Vector3 get_position_by_transform(mach_vm_address_t mach_transform_ptr, task_t task)
{
    mach_vm_address_t transObj = Read<mach_vm_address_t>(mach_transform_ptr + 0x10, task);
    if (!transObj || transObj < 0x1000000) return Vector3{0,0,0};

    Vector3 r = try_get_position(transObj, 0x38, 0x40, task);
    if (is_valid_pos(r)) return r;

    r = try_get_position(transObj, 0x40, 0x48, task);
    if (is_valid_pos(r)) return r;

    r = try_get_position(transObj, 0x30, 0x38, task);
    if (is_valid_pos(r)) return r;

    return Vector3{0,0,0};
}

Vector3 WorldToScreen(Vector3 object, SO2_Matrix mat, CGFloat ScreenWidth, CGFloat ScreenHeight)
{
    float screenX = (mat.m11 * object.x) + (mat.m21 * object.y) + (mat.m31 * object.z) + mat.m41;
    float screenY = (mat.m12 * object.x) + (mat.m22 * object.y) + (mat.m32 * object.z) + mat.m42;
    float screenW = (mat.m14 * object.x) + (mat.m24 * object.y) + (mat.m34 * object.z) + mat.m44;

    Vector3 result;
    if(screenW < 0.0001f) {
        result.z = -1;
        return result;
    }

    float camX = ScreenWidth / 2.0f;
    float camY = ScreenHeight / 2.0f;
    result.x = camX + (camX * screenX / screenW);
    result.y = camY - (camY * screenY / screenW);
    result.z = screenW;
    return result;
}
