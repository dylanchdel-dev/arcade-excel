#!/usr/bin/env python3
"""Arma el sitio estático completo descargando SOLO motor libre y Freedoom oficial.
Necesita internet únicamente en equipo de publicación (CI), no en dispositivos de jugadores.
"""
from pathlib import Path
from urllib.request import Request,urlopen
import tempfile, zipfile, shutil, hashlib, struct, time
ROOT=Path(__file__).resolve().parent
ENGINE_COMMIT='e0ba81004e27e7d66141925dfebb091a558e2fe8'
ENGINE=f'https://github.com/danborden1/doom-web/archive/{ENGINE_COMMIT}.zip'
DATA='https://github.com/freedoom/freedoom/releases/download/v0.13.0/freedoom-0.13.0.zip'
HASHES={
    'freedoom1.wad':'7323bcc168c5a45ff10749b339960e98314740a734c30d4b9f3337001f9e703d',
    'freedoom2.wad':'a8772e088847032510d97ba2312406a6998f21cbab44d4ff10696faa9c0ecd4b',
    'websockets-doom.wasm':'4a55e4381d374b9bf347116e8c6f52547bb990fd7fc28a5e21af354830f80f78',
}

def verify(file):
    actual=hashlib.sha256(file.read_bytes()).hexdigest()
    if actual!=HASHES[file.name]:raise RuntimeError('SHA256 inesperado: '+file.name)
    print('SHA256 verificado:',file.name,actual,flush=True)

def get(url,dest):
    print('Obteniendo:',url,flush=True)
    for attempt in range(3):
        try:
            with urlopen(Request(url, headers={'User-Agent':'ArcadeExcelV12/1.0'}), timeout=180) as source,open(dest,'wb') as out:
                shutil.copyfileobj(source,out)
            if dest.stat().st_size < 1024: raise RuntimeError('Descarga incompleta: '+url)
            return
        except Exception:
            if attempt==2:raise
            print('Reintentando descarga temporalmente fallida...',flush=True)
            time.sleep(2**(attempt+1))

def safe_extract(zf,dest):
    for item in zf.infolist():
        resolved=(dest/item.filename).resolve()
        if not resolved.is_relative_to(dest.resolve()):raise RuntimeError('Ruta insegura en ZIP')
    zf.extractall(dest)

def iwad_check(file):
    if file.stat().st_size < 10_000_000:raise RuntimeError('IWAD demasiado pequeño')
    with file.open('rb') as f:
        if f.read(4)!=b'IWAD':raise RuntimeError('IWAD inválido')
    verify(file)
    data=file.read_bytes()
    _,count,offset=struct.unpack('<4sii',data[:12])
    if count<1 or offset<12 or offset+count*16>len(data):raise RuntimeError('Directorio WAD inválido')
    names=set()
    for i in range(count):
        start,size,name=struct.unpack('<ii8s',data[offset+i*16:offset+(i+1)*16])
        if start<0 or size<0 or start+size>len(data):raise RuntimeError('Recurso WAD truncado')
        names.add(name.rstrip(b'\0').decode('ascii'))
    expected=({f'E{e}M{m}' for e in range(1,5) for m in range(1,10)} if file.name=='freedoom1.wad' else {f'MAP{m:02d}' for m in range(1,33)})
    if not expected<=names:raise RuntimeError('Faltan niveles oficiales')
    print('Niveles verificados:',len(expected),flush=True)

with tempfile.TemporaryDirectory() as d:
    temp=Path(d); get(ENGINE,temp/'engine.zip');get(DATA,temp/'freedoom.zip')
    with zipfile.ZipFile(temp/'engine.zip') as z:safe_extract(z,temp/'engine')
    with zipfile.ZipFile(temp/'freedoom.zip') as z:safe_extract(z,temp/'data')
    eng=temp/'engine'/('doom-web-'+ENGINE_COMMIT)
    required=['index.html','websockets-doom.js','websockets-doom.wasm','COPYING','FREEDOOM-COPYING.txt','FREEDOOM-CREDITS.txt']
    for name in required:
        if not (eng/name).is_file():raise RuntimeError('No se encontró archivo del motor '+name)
    verify(eng/'websockets-doom.wasm')
    if (eng/'websockets-doom.wasm').read_bytes()[:8]!=b'\0asm\x01\0\0\0':raise RuntimeError('WebAssembly inválido')
    wads={name: list((temp/'data').rglob(name)) for name in ('freedoom1.wad','freedoom2.wad')}
    for name,files in wads.items():
        if len(files)!=1:raise RuntimeError('WAD ausente o duplicado: '+name)
        iwad_check(files[0])
    original=(ROOT/'freedoom-player.html').read_text(encoding='utf-8')
    if '__PHASE__' not in original:raise RuntimeError('Plantilla de campañas inválida')
    for i in (1,2):
        target=ROOT/'juegos'/('freedoom' if i==1 else 'freedoom2')
        target.mkdir(parents=True,exist_ok=True)
        for f in required+['default.cfg']:
            if (eng/f).is_file():shutil.copy2(eng/f,target/f)
        name=f'freedoom{i}.wad'
        shutil.copy2(wads[name][0],target/name)
        shutil.copy2(ROOT/'freedoom-default.cfg',target/'default.cfg')
        (target/'index.html').write_text(original.replace('__PHASE__',str(i)),encoding='utf-8')
        print('Preparado:',name,'bytes:',(target/name).stat().st_size,flush=True)
print('V12 empaquetada; lista para desplegar como sitio estático.',flush=True)
