const fs=require('fs');
const path=require('path');
const sourceRoot=process.argv[2]||'becak-source';
const placePath=path.join(sourceRoot,'maps/becak-e-bike/place.rbxlx');
if(!fs.existsSync(placePath)) throw new Error('Missing Becak legacy place baseline: '+placePath);
let xml=fs.readFileSync(placePath,'utf8');
const cdata=s=>String(s).replaceAll(']]>',']]]]><![CDATA[>');
const targets={
  BecakEBike_CityDetails:'maps/becak-e-bike/world.details.server.lua',
  BecakEBike_CityRealismArchitecture:'maps/becak-e-bike/city.realism.architecture.server.lua',
  BecakEBike_VehicleRealism:'maps/becak-e-bike/vehicle.realism.server.lua',
  BecakEBike_VehicleGeometryRealism:'maps/becak-e-bike/vehicle.geometry.realism.server.lua'
};
function escapeRe(s){return s.replace(/[.*+?^${}()|[\]\\]/g,'\\$&')}
function scriptXml(name,src,ref){return `<Item class="Script" referent="${ref}"><Properties><string name="Name">${name}</string><bool name="Disabled">false</bool><ProtectedString name="Source"><![CDATA[${src}]]></ProtectedString></Properties></Item>`}
function insertServerScript(item){
  const starter=xml.indexOf('<Item class="StarterPlayer"');
  if(starter<0) throw new Error('StarterPlayer boundary not found in legacy place');
  const close=xml.lastIndexOf('</Item>',starter);
  if(close<0) throw new Error('ServerScriptService closing boundary not found');
  xml=xml.slice(0,close)+item+xml.slice(close);
}
let added=0,replaced=0,index=0;
for(const [name,file] of Object.entries(targets)){
  const full=path.join(sourceRoot,file);
  if(!fs.existsSync(full)) throw new Error('Missing V3 source '+file);
  const src=cdata(fs.readFileSync(full,'utf8'));
  const re=new RegExp(`(<string name="Name">${escapeRe(name)}<\\/string><bool name="Disabled">false<\\/bool><ProtectedString name="Source"><!\\[CDATA\\[)([\\s\\S]*?)(\\]\\]><\\/ProtectedString>)`);
  if(re.test(xml)){
    xml=xml.replace(re,`$1${src}$3`); replaced++;
    console.log('[Becak V3 RR] replaced',name);
  }else{
    insertServerScript(scriptXml(name,src,`BECAK_V3_RR_${++index}`)); added++;
    console.log('[Becak V3 RR] added',name);
  }
}
const required=['ACC_BecakWorldV3','BecakWorldV3VisualAuthority','ACC_BecakCityDetails','ACC_BecakVehicleRealism','ACC_BecakVehicleGeometryRealism','BecakEBike_CityRealismArchitecture','BecakEBike_VehicleRealism','BecakEBike_VehicleGeometryRealism'];
for(const token of required) if(!xml.includes(token)) throw new Error('V3 migration validation missing '+token);
fs.writeFileSync(placePath,xml);
console.log(`[Becak V3 RR] migration complete replaced=${replaced} added=${added} bytes=${Buffer.byteLength(xml)}`);
