
**Round 3: one gate leaf drew dark (F813, my own F810 bug)**
- To make the turned-round leaf's ring face the front, I mirrored it with a -1 scale. That turns its light
  inside out, so it drew dark. The camera chat spotted it. Fix: the leaf now gets a real mirrored copy of its shape
  (normals and triangle order fixed), and it is mirrored again if the leaf is ever rebuilt.
