"""Video key frames -> direction numbers for the dwarf (Blender axes: x = his left, y = his back (front = -y), z = up)."""
import json,math,numpy as np
T={r["i"]:r for r in json.load(open("track.json"))}
MOVES={"Chop":[271,327,333,340,364],"Stab":[364,390,396,404,427],"Overhead":[427,513,519,530,571]}
NAMES=["ready","windup","middle","hit","recovery"]
def W(f):  # world joints averaged over f-2..f+2, Blender axes
    vs=[np.array(T[i]["w"]) for i in range(f-2,f+3) if T[i].get("w")]
    w=np.mean(vs,0); return np.stack([w[:,0],w[:,2],-w[:,1]],1)
def P(f):
    vs=[np.array(T[i]["px"])[:,:2] for i in range(f-2,f+3) if T[i].get("px")]; return np.mean(vs,0)
p0=P(271); torso0=np.linalg.norm((p0[11]+p0[12])/2-(p0[23]+p0[24])/2); hip0=(p0[23][1]+p0[24][1])/2; sw0=np.linalg.norm(p0[11]-p0[12])
out={}
yaw=lambda v:math.degrees(math.atan2(v[1],v[0]))  # left-right line seen from above; + = turned to his left
for m,fr in MOVES.items():
    out[m]=[]
    for n,f in zip(NAMES,fr):
        w=W(f); p=P(f)
        A=(np.linalg.norm(w[11]-w[13])+np.linalg.norm(w[13]-w[15])+np.linalg.norm(w[12]-w[14])+np.linalg.norm(w[14]-w[16]))/2
        sh=(w[11]+w[12])/2; hp=(w[23]+w[24])/2; sp=sh-hp
        k={"name":n,"frame":f,
           "lw":[float(x) for x in (w[15]-w[11])/A],"rw":[float(x) for x in (w[16]-w[12])/A],"le":[float(x) for x in (w[13]-w[11])/A],"re":[float(x) for x in (w[14]-w[12])/A],
           "hip_yaw":yaw(w[23]-w[24]),"sh_yaw":yaw(w[11]-w[12]),
           "lean":math.degrees(math.atan2(-sp[1],sp[2])),  # + = top forward (-y)
           "side":math.degrees(math.atan2(sp[0],sp[2])),   # + = top toward his left
           "hip_drop":float(((p[23][1]+p[24][1])/2-hip0)/torso0),
           "shW":float(np.linalg.norm(p[11]-p[12])/sw0)}
        # chest turn: the camera's 3D guess and the shoulder width in the picture disagree (arms reaching across
        # narrow the shoulders too): use the middle of the two, the sign from the 3D guess
        px=math.degrees(math.acos(min(1.0,k["shW"]/1.17)))
        k["chest_yaw"]=0.5*(k["sh_yaw"]+math.copysign(px,k["sh_yaw"]))
        out[m].append({a:(round(float(b),3) if isinstance(b,(float,np.floating)) else ([round(float(x),3) for x in b] if isinstance(b,list) else b)) for a,b in k.items()})
        print(m,n,"hip %.0f chest %.0f lean %.0f" % (out[m][-1]["hip_yaw"],out[m][-1]["chest_yaw"],out[m][-1]["lean"]))
json.dump(out,open("video_targets.json","w"),indent=1)
