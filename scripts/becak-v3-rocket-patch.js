const fs=require('fs');
const path=require('path');
const sourceRoot=process.argv[2]||'becak-source';
const placePath=path.join(sourceRoot,'maps/becak-e-bike/place.rbxlx');
if(!fs.existsSync(placePath)) throw new Error('Missing Becak legacy place baseline: '+placePath);
let xml=fs.readFileSync(placePath,'utf8');
const cdata=s=>String(s).replaceAll(']]>',']]]]><![CDATA[>');
const targets={
  BecakEBike_CityDetails:{file:'maps/becak-e-bike/world.details.server.lua',requireExisting:false},
  BecakEBike_CityRealismArchitecture:{file:'maps/becak-e-bike/city.realism.architecture.server.lua',requireExisting:false},
  BecakEBike_VehicleMasterplan:{file:'maps/becak-e-bike/masterplan.vehicle.server.lua',requireExisting:true},
  BecakEBike_VehicleRealism:{file:'maps/becak-e-bike/vehicle.realism.server.lua',requireExisting:false},
  BecakEBike_VehicleGeometryRealism:{file:'maps/becak-e-bike/vehicle.geometry.realism.server.lua',requireExisting:false},
  BecakEBike_TrafficNPC:{file:'maps/becak-e-bike/traffic.npc.server.lua',requireExisting:true},
  BecakEBike_MobileSafeArea:{file:'maps/becak-e-bike/mobile.safearea.client.lua',requireExisting:true}
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
for(const [name,spec] of Object.entries(targets)){
  const full=path.join(sourceRoot,spec.file);
  if(!fs.existsSync(full)) throw new Error('Missing V3 source '+spec.file);
  const src=cdata(fs.readFileSync(full,'utf8'));
  const re=new RegExp(`(<string name="Name">${escapeRe(name)}<\\/string><bool name="Disabled">false<\\/bool><ProtectedString name="Source"><!\\[CDATA\\[)([\\s\\S]*?)(\\]\\]><\\/ProtectedString>)`);
  if(re.test(xml)){
    xml=xml.replace(re,`$1${src}$3`);replaced++;
    console.log('[Becak V3 RR] replaced',name);
  }else{
    if(spec.requireExisting) throw new Error('Required embedded authority missing: '+name);
    insertServerScript(scriptXml(name,src,`BECAK_V3_RR_${++index}`));added++;
    console.log('[Becak V3 RR] added',name);
  }
}
const required=[
  'ACC_BecakWorldV3','BecakWorldV3VisualAuthority','ACC_BecakCityDetails',
  'ACC_BecakVehicleMasterplan','ACC_BecakVehicleRealism','ACC_BecakVehicleGeometryRealism',
  'ACC_BecakTrafficNPCEnhancement','ACC_BecakMobileSafeAreaEnhancement',
  'BecakEBike_CityRealismArchitecture','BecakEBike_VehicleMasterplan',
  'BecakEBike_VehicleRealism','BecakEBike_VehicleGeometryRealism',
  'BecakEBike_TrafficNPC','BecakEBike_MobileSafeArea',
  "BecakPassengerCompartmentPosition','FRONT", "BecakDriverPosition','BEHIND_PASSENGER",
  "BecakTrafficRealScaleRemesh','v3.2", "ACC_BecakUILocation','RIGHT_TOP"
];
for(const token of required) if(!xml.includes(token)) throw new Error('V3.2 migration validation missing '+token);
fs.writeFileSync(placePath,xml);
console.log(`[Becak V3 RR] V3.2 migration complete replaced=${replaced} added=${added} bytes=${Buffer.byteLength(xml)}`);
