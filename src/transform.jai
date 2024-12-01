Transform :: struct {
    position: Vector3;
    rotation: Quaternion = .{0, 0, 0, 1};
    size: Vector3 = .{1, 1, 1};

    dirty := false;
    matrix: Matrix4 = Matrix4_Identity;
}

transform_make :: (pos: Vector3 = .{0, 0, 0}, rot: Quaternion = .{0, 0, 0, 1}, size: Vector3 = .{1, 1, 1}) -> Transform {
    xform : Transform;
    xform.position = pos;
    xform.rotation = rot;
    xform.size = size;
    xform.dirty = true;
    return xform;
}

get_matrix :: (self: *Transform) -> Matrix4 {
    if self.dirty {
        r := rotation_matrix(Matrix4, self.rotation);
        s := make_scale_matrix4(self.size);
        t := make_translation_matrix4(self.position);
                    
        self.matrix = t * r * s;
        self.dirty = false;
    }
    return self.matrix;
}

look_at :: (transform: *Transform, dir: Vector3) {
    d := dot(FORWARD, dir);
    angle := acos(d);
    axis := cross(dir, FORWARD);
    set_from_axis_and_angle(*transform.rotation, axis, angle);
    transform.dirty = true;
}

set_position :: (using transform: *Transform, pos: Vector3) {
    position = pos;
    dirty = true;
}

get_forward :: (using transform: *Transform) -> Vector3 {
    m := get_matrix(transform);
    return row(m, 2).xyz;
}

// transform_push_constant :: (using self: *Transform, cmd: VkCommandBuffer, layout: VkPipelineLayout) {
//     mat := get_matrix(self);
//     set_push_constants(mat, cmd, layout);
// }

deinit :: (using self: *Transform) { }
