"""Compose the app hero images (Assets/img/apps/<slug>/hero.jpg).

Each hero is 1600x1000: a background (gradient, glows, or Poke Ball imprints) with Tim's
bezelled screenshots on top. It's composed in floating point and dithered once at the end,
since 8-bit gradients band, then saved as JPEG quality 100 with 4:4:4 chroma (the lightbox
target; build-media.py derives the q95/q97 page variants from it).

Sources are Tim's lossless bezel PNGs, never images pasted into chat (those arrive as
lossy WebP), kept in the repo under Design/app-heroes/<slug>/ so a hero can be re-tweaked
on any machine: micropoints-1/2.png, ipokedex-1/2.png, Mercari-1/2/3.png, pixiv-1/2.png
and icomics-devices.webp (from icomics.net; swap in a PNG export if one turns up).
Design/ is never copied into Build/. Needs numpy as well as Pillow.

    python3 Scripts/app-heroes.py [slug ...]          # all heroes, or just these
    python3 Scripts/app-heroes.py --from DIR [slug ...] # sources from elsewhere

Afterwards run Scripts/strip-exif.py on the heroes and Scripts/build-media.py.
"""
import sys,math
from pathlib import Path
import numpy as np
from PIL import Image, ImageDraw
ROOT=Path(__file__).resolve().parent.parent
args=sys.argv[1:]
D=str(ROOT/'Design/app-heroes')+'/'
if args[:1]==['--from']:
    if len(args)<2: sys.exit(__doc__)
    D=args[1].rstrip('/')+'/'; args=args[2:]
REPO=str(ROOT/'Assets/img/apps')+'/'
W,H=1600,1000
def box(a,r,axis):
    if r<1: return a
    pad=[(0,0)]*a.ndim; pad[axis]=(r+1,r); p=np.pad(a,pad,mode='edge'); c=np.cumsum(p,axis=axis)
    hi=np.take(c,range(2*r+1,c.shape[axis]),axis=axis); lo=np.take(c,range(0,c.shape[axis]-2*r-1),axis=axis)
    return (hi-lo)/(2*r+1)
def blur(a,sigma):   # three box passes per axis ~ Gaussian
    r=max(1,int(round((math.sqrt(12*sigma*sigma/3+1)-1)/2)))
    for ax in (0,1):
        for _ in range(3): a=box(a,r,ax)
    return a
def radial(inner,outer,cy=0.42,p=1.2):
    y,x=np.mgrid[0:H,0:W].astype(np.float64); R=math.hypot(W/2,H/2)
    t=np.minimum(1,np.hypot(x-W/2,y-H*cy)/R)**p
    return np.array(inner,float)[None,None,:]*(1-t[...,None])+np.array(outer,float)[None,None,:]*t[...,None]
def linear(top,bottom,p=1.0):   # vertical gradient; p>1 holds the top colour longer
    t=((np.arange(H,dtype=np.float64)/(H-1))**p)[:,None,None]
    return np.broadcast_to(np.array(top,float)*(1-t)+np.array(bottom,float)*t,(H,W,3)).copy()
def over(img,color,alpha):   # color: rgb tuple or HxWx3 array; alpha: HxW in 0..1
    a=np.clip(alpha,0,1)[...,None]; return img*(1-a)+np.asarray(color,float)*a
def fmask(pil_L): return np.asarray(pil_L,dtype=np.float64)/255
def shift(a,dx,dy):
    out=np.zeros_like(a); h,w=a.shape
    out[max(dy,0):h+min(dy,0), max(dx,0):w+min(dx,0)]=a[max(-dy,0):h-max(dy,0), max(-dx,0):w-max(dx,0)]; return out
def phones_over(img,phones,h,tops,gap,sa,sig,dy,order):
    sc=[q.resize((round(q.width*h/q.height),h),Image.LANCZOS) for q in phones]
    x=(W-(sum(s.width for s in sc)+gap*(len(sc)-1)))//2; pos=[]
    for s in sc: pos.append(x); x+=s.width+gap
    for i in order:
        s=np.asarray(sc[i],dtype=np.float64)/255; px,py=pos[i],tops[i]
        canvas_a=np.zeros((H,W)); rgb=np.zeros((H,W,3))
        y0,y1=max(py,0),min(py+s.shape[0],H); x0,x1=max(px,0),min(px+s.shape[1],W)
        canvas_a[y0:y1,x0:x1]=s[y0-py:y1-py,x0-px:x1-px,3]; rgb[y0:y1,x0:x1]=s[y0-py:y1-py,x0-px:x1-px,:3]*255
        img=over(img,(0,0,0),blur(shift(canvas_a,0,dy),sig)*sa)
        img=over(img,rgb,canvas_a)
    return img
def save(img,slug):
    rng=np.random.default_rng(sum(map(ord,slug)))   # seeded per app: reruns are identical
    img=img+rng.random(img.shape)-rng.random(img.shape)   # triangular dither, +-1 level
    out=Image.fromarray(np.clip(np.round(img),0,255).astype(np.uint8),'RGB')
    out.save(REPO+slug+'/hero.jpg',quality=100,subsampling=0,optimize=True,progressive=True)
    print('wrote',REPO+slug+'/hero.jpg')
def L(name):   # a source file found anywhere under SOURCE_DIR (Tim keeps per-app folders)
    hits=sorted(Path(D).rglob(name))
    if not hits: sys.exit(f'{name} not found under {D}')
    return Image.open(hits[0]).convert('RGBA')
def pokeball_mask(s):
    m=Image.new('L',(s,s),0); d=ImageDraw.Draw(m)
    d.ellipse((0,0,s-1,s-1),fill=255); b=int(s*0.085); d.rectangle((0,s//2-b//2,s,s//2+b//2),fill=0)
    r1=int(s*0.21); d.ellipse((s//2-r1,s//2-r1,s//2+r1,s//2+r1),fill=0)
    r2=int(s*0.13); d.ellipse((s//2-r2,s//2-r2,s//2+r2,s//2+r2),fill=255); return m
which=args or ['micropoints','ipokedex','mercari-japan','icomics','pixiv']
if 'micropoints' in which:
    img=radial((74,190,62),(22,92,20),cy=0.45,p=1.3)
    g=Image.new('L',(W,H),0); gd=ImageDraw.Draw(g)
    for (x,y,r,a) in [(180,180,90,40),(1420,160,70,35),(1500,820,110,30),(120,860,80,30),(800,940,60,25)]:
        gd.ellipse((x-r,y-r,x+r,y+r),fill=a)
    img=over(img,(150,255,140),blur(fmask(g),18))
    img=phones_over(img,[L('micropoints-1.png'),L('micropoints-2.png')],1086,[18,18],120,0.45,22,14,[0,1])
    save(img,'micropoints')
if 'ipokedex' in which:
    img=radial((196,28,36),(92,8,14),cy=0.42,p=1.2)
    balls=[(45,300,480,15,1.0),(40,850,440,-15,0.75),(1560,140,460,-15,0.9),(1555,700,520,15,1.0),
           (770,45,340,-15,0.7),(820,475,300,-15,0.8),(780,905,300,15,0.8)]
    for (cx,cy,sz,ang,k) in balls:
        m=pokeball_mask(sz).rotate(ang,resample=Image.BICUBIC,expand=True)
        P=40   # padded canvas so the emboss shifts don't streak where a ball crosses the edge
        big=Image.new('L',(W+2*P,H+2*P),0); big.paste(m,(cx-m.width//2+P,cy-m.height//2+P)); f=fmask(big)
        crop=lambda a: a[P:P+H,P:P+W]
        img=over(img,(40,0,4),crop(f)*0.30*k)
        img=over(img,(20,0,2),crop(blur(np.clip(f-shift(f,6,6),0,1),5))*0.75*k)
        img=over(img,(255,140,140),crop(blur(np.clip(f-shift(f,-3,-3),0,1),2))*0.22*k)
    img=phones_over(img,[L('ipokedex-2.png'),L('ipokedex-1.png')],1086,[18,18],120,0.5,22,14,[0,1])
    save(img,'ipokedex')
if 'mercari-japan' in which:
    img=np.full((H,W,3),255.0)
    img=phones_over(img,[L('Mercari-1.png'),L('Mercari-2.png'),L('Mercari-3.png')],944,[28,28,28],50,0.28,26,18,[0,2,1])
    save(img,'mercari-japan')
if 'icomics' in which:
    # White, like Mercari, behind the iPad + iPhone render (both devices in one image).
    img=np.full((H,W,3),255.0)
    dev=L('icomics-devices.webp'); h=round(dev.height*1380/dev.width)
    img=phones_over(img,[dev],h,[(H-h)//2+10],0,0.28,26,18,[0])
    save(img,'icomics')
if 'pixiv' in which:
    # pixiv blue (its marketing puts the bezels on blue): the icon's exact #0096FA at the
    # top, held through the upper half, then darkening toward the bottom, so the card
    # matches its icon. WWDC-style framing: the iPhone 5 screens (y 237-1373
    # in the 1602px bezel PNGs) fill the height with 15px of phone above and below, so
    # the rounded ends never show.
    img=linear((0,150,250),(0,108,200),p=2.2)
    s=970/1136
    img=phones_over(img,[L('pixiv-1.png'),L('pixiv-2.png')],round(1602*s),[round(15-237*s)]*2,80,0.45,24,16,[0,1])
    save(img,'pixiv')
