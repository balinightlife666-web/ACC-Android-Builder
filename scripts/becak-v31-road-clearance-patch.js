const fs=require('fs');
const root=process.argv[2]||'becak-source';
const place=`${root}/maps/becak-e-bike/place.rbxlx`;
let xml=fs.readFileSync(place,'utf8');
const cdata=s=>String(s).replaceAll(']]>',']]]]><![CDATA[>');
const source=`-- BECAK E-BIKE — NUSAKARYA V3.1 ROAD CLEARANCE HOTFIX\nlocal Workspace=game:GetService('Workspace')\nlocal root=Workspace:WaitForChild('BecakEBike',30) if not root then return end\nlocal world=root:WaitForChild('Nusakarya',30) if not world then return end\ntask.wait(3)\nlocal removed=0\nlocal moved=0\nlocal function isRoadCorridor(pos)\n  local x,z=math.abs(pos.X),math.abs(pos.Z)\n  if x<34 or z<34 then return true end\n  if math.abs(pos.Z-300)<34 or math.abs(pos.Z+300)<34 then return true end\n  if math.abs(pos.X-150)<34 or math.abs(pos.X+150)<34 then return true end\n  return false\nend\nlocal function looksLikePoleOrTree(p)\n  local n=string.lower(p.Name)\n  return n:find('pole',1,true) or n:find('utility',1,true) or n:find('lamp',1,true) or n:find('trunk',1,true) or n:find('tree',1,true) or n:find('palm',1,true) or n:find('leaf',1,true) or n:find('crown',1,true)\nend\nfor _,d in ipairs(world:GetDescendants()) do\n  if d:IsA('BasePart') and looksLikePoleOrTree(d) and isRoadCorridor(d.Position) then\n    local n=string.lower(d.Name)\n    if n:find('leaf',1,true) or n:find('crown',1,true) then\n      d:Destroy();removed+=1\n    else\n      d:Destroy();removed+=1\n    end\n  end\nend\n-- clear generated V3 vegetation from carriageways/crosswalk approaches as a second pass\nlocal v3=world:FindFirstChild('NusakaryaV3')\nif v3 then\n  local veg=v3:FindFirstChild('V3Vegetation')\n  if veg then\n    for _,d in ipairs(veg:GetDescendants()) do\n      if d:IsA('BasePart') and isRoadCorridor(d.Position) then d:Destroy();removed+=1 end\n    end\n  end\nend\nWorkspace:SetAttribute('ACC_BecakRoadClearanceHotfix','v3.1')\nWorkspace:SetAttribute('BecakRoadClearanceRemovedObjects',removed)\nWorkspace:SetAttribute('BecakRoadClearanceCenterline','CLEAR')\nWorkspace:SetAttribute('BecakRoadClearanceCrosswalks','CLEAR')\nprint('[BECAK E-BIKE] V3.1 ROAD CLEARANCE PASS',removed,moved)\n`;
if(xml.includes('BecakEBike_V31RoadClearance')){
  const re=/(<string name="Name">BecakEBike_V31RoadClearance<\/string><bool name="Disabled">false<\/bool><ProtectedString name="Source"><!\[CDATA\[)([\s\S]*?)(\]\]><\/ProtectedString>)/;
  if(!re.test(xml)) throw new Error('Existing V31 road-clearance script malformed');
  xml=xml.replace(re,`$1${cdata(source)}$3`);
}else{
  const anchor='<Item class="ServerScriptService" referent="S"><Properties><string name="Name">ServerScriptService</string></Properties>';
  if(!xml.includes(anchor)) throw new Error('ServerScriptService anchor missing');
  const item=`<Item class="Script"><Properties><string name="Name">BecakEBike_V31RoadClearance</string><bool name="Disabled">false</bool><ProtectedString name="Source"><![CDATA[${cdata(source)}]]></ProtectedString></Properties></Item>`;
  xml=xml.replace(anchor,anchor+item);
}
if(!xml.includes("ACC_BecakRoadClearanceHotfix','v3.1")) throw new Error('Road-clearance marker missing');
fs.writeFileSync(place,xml);
console.log('[Becak V3.1] road-clearance patch complete',Buffer.byteLength(xml),'bytes');
