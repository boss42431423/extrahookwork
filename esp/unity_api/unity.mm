#import "unity.h"

struct c_matrix_new {
    float m[4][4];
};

struct TMatrix48 {
    Vector4 position;
    Vector4 rotation;
    Vector4 scale;
};

static Vector3 walk_hierarchy(mach_vm_address_t matrix_list, mach_vm_address_t matrix_indices,
                              Vector3 result, int transformIndex, size_t eSize,
                              int rotOff, int posOff, int scaleOff, task_t task) {
    int max_safety = 50;
    while (transformIndex >= 0 && max_safety-- > 0) {
        mach_vm_address_t base = matrix_list + eSize * (size_t)transformIndex;
        Vector4 rot = Read<Vector4>(base + rotOff, task);
        Vector3 pos = Read<Vector3>(base + posOff, task);
        Vector3 sc  = Read<Vector3>(base + scaleOff, task);

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
    return result;
}

static Vector3 try_get_position(mach_vm_address_t transObj, int matOff, int idxOff, task_t task) {
    mach_vm_address_t matrix = Read<mach_vm_address_t>(transObj + matOff, task);
    if (!matrix) return Vector3{0,0,0};

    mach_vm_address_t matrix_list = Read<mach_vm_address_t>(matrix + 0x18, task);
    mach_vm_address_t matrix_indices = Read<mach_vm_address_t>(matrix + 0x20, task);
    if (!matrix_list || !matrix_indices) return Vector3{0,0,0};

    int index = Read<int>(transObj + idxOff, task);

    // Layout A: 40 bytes — rotation(16) + position(12) + scale(12)
    {
        size_t eSize = 40;
        int rotOff = 0, posOff = 16, scaleOff = 28;
        Vector3 result = Read<Vector3>(matrix_list + eSize * (size_t)index + posOff, task);
        int ti = Read<int>(matrix_indices + sizeof(int) * (size_t)index, task);
        if (ti < 0 && (result.x != 0 || result.y != 0 || result.z != 0)) return result;
        if (ti >= 0) {
            Vector3 r = walk_hierarchy(matrix_list, matrix_indices, result, ti, eSize, rotOff, posOff, scaleOff, task);
            if (r.x != 0 || r.y != 0 || r.z != 0) return r;
        }
    }

    // Layout B: 48 bytes — position(16) + rotation(16) + scale(16)
    {
        size_t eSize = 48;
        int posOff = 0, rotOff = 16, scaleOff = 32;
        Vector3 result = Read<Vector3>(matrix_list + eSize * (size_t)index + posOff, task);
        int ti = Read<int>(matrix_indices + sizeof(int) * (size_t)index, task);
        if (ti < 0 && (result.x != 0 || result.y != 0 || result.z != 0)) return result;
        if (ti >= 0) {
            Vector3 r = walk_hierarchy(matrix_list, matrix_indices, result, ti, eSize, rotOff, posOff, scaleOff, task);
            if (r.x != 0 || r.y != 0 || r.z != 0) return r;
        }
    }

    return Vector3{0,0,0};
}

Vector3 get_position_by_transform(mach_vm_address_t mach_transform_ptr, task_t task)
{
    mach_vm_address_t transObj = Read<mach_vm_address_t>(mach_transform_ptr + 0x10, task);
    if (!transObj) return Vector3{0,0,0};

    // Unity 2020/2021: matrix at +0x38, index at +0x40
    Vector3 r = try_get_position(transObj, 0x38, 0x40, task);
    if (r.x != 0 || r.y != 0 || r.z != 0) return r;

    // Unity 2022+: matrix at +0x40, index at +0x48
    r = try_get_position(transObj, 0x40, 0x48, task);
    if (r.x != 0 || r.y != 0 || r.z != 0) return r;

    // Unity alt: matrix at +0x30, index at +0x38
    r = try_get_position(transObj, 0x30, 0x38, task);
    if (r.x != 0 || r.y != 0 || r.z != 0) return r;

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
