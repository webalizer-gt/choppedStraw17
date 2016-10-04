--
-- AddChoppedStraw
--
-- @author: webalizer
-- @version: 17.01b
-- @date: 16 Sep 2016
-- @history: 17.01b (16 Sep 2016): initial implementation
--
--
-- @usage:
--[[
	0)	reference this .lua file in the map's <extraSourceFiles>

	1)	add to map's .lua file, :new() function, at the beginning:

		-- AddChoppedStraw # START #
		local AddChoppedStrawPath =  Utils.getFilename('AddChoppedStraw.lua', baseDirectory);
		if fileExists(AddChoppedStrawPath) then
			source(AddChoppedStrawPath);
			AddChoppedStraw:run(baseDirectory);
		end;
		-- AddChoppedStraw #  END  #

	2)	add to map's modDesc.xml:

	<AddChoppedStraw globalFertilization="true">
		<strawType name="lightStraw">
			<binding fruitType="wheat" strawOutputFront="false" allowFertilization="true" soilmodN="1" soilmodPK="1" />
			<binding fruitType="barley" strawOutputFront="false" allowFertilization="true" soilmodN="1" soilmodPK="1" />
		</strawType>
		<strawType name="darkStraw">
			<binding fruitType="rape" strawOutputFront="false" allowFertilization="true" soilmodN="2" soilmodPK="1" />
		</strawType>
		<strawType name="maizeStraw">
			<binding fruitType="maize" strawOutputFront="true" allowFertilization="true" soilmodN="2" soilmodPK="2" />
		</strawType>
		<strawType name="soybeanStraw">
			<binding fruitType="soybean" strawOutputFront="true" allowFertilization="false" />
		</strawType>
		<strawType name="sunflowerStraw">
			<binding fruitType="sunflower" strawOutputFront="true" allowFertilization="false" />
		</strawType>
	</AddChoppedStraw>

		Adjust the "globalFertilization" tag to your preference.
--]]

-- ##################################################


AddChoppedStraw = {};
AddChoppedStraw.version = '17.01b';
AddChoppedStraw.author = 'webalizer';

function AddChoppedStraw:run(baseDirectory)

	if self.initialized then return end;

	local xmlFilePath =  Utils.getFilename('modDesc.xml', baseDirectory);
	if fileExists(xmlFilePath) then
		local xmlFile = loadXMLFile('modDescXML', xmlFilePath);
		local key = 'modDesc.AddChoppedStraw';

		if hasXMLProperty(xmlFile, key) then

				print(('AddChoppedStraw v%s by %s loaded'):format(AddChoppedStraw.version, AddChoppedStraw.author));
				self:registerStrawTypes(xmlFile, key);
			else
				print('Error: AddChoppedStraw could not find directory.');
			end; -- END strawDirectory ~= nil
		end; -- END hasXMLProperty(xmlFile, key)
		delete(xmlFile);
	end; -- END fileExists(xmlFilePath)

	self.initialized = true;
end;

function AddChoppedStraw:registerStrawTypes(xmlFile, key)
	-- Read straw informations into ChoppedStraw globalFertilization
	-- Use fertilization in general? (default=true)
	if hasXMLProperty(xmlFile, key..'#globalFertilization') then
		ChoppedStraw.globalFertilization = Utils.getNoNil(getXMLBool(xmlFile, key..'#globalFertilization'),true);
	end;
	-- Create array for binding fruitTypes to strawTypes
	ChoppedStraw.strawBindings = {};
	local a = 0;
	while true do
		local strawTypeKey = key .. ('.strawType(%d)'):format(a);
		if not hasXMLProperty(xmlFile, strawTypeKey) then
			break;
		end;

		local strawType = getXMLString(xmlFile, strawTypeKey..'#name');
		if strawType == nil then
			print(('Error: missing "name" attribute for strawType #%d in "AddChoppedStraw". Adding strawTypes aborted.'):format(a));
			break;
		end;
		local strawTypeFoliageId = g_currentMission:loadFoliageLayer(strawType, -5, -1, true, "alphaBlendStartEnd");

		local b = 0;
		while true do
			local binding = strawTypeKey .. ('.binding(%d)'):format(b);
			if not hasXMLProperty(xmlFile, binding) then
				break;
			end;
			local bindingFruitType = getXMLString(xmlFile, binding..'#fruitType');
			local bindingStrawOutputFront = Utils.getNoNil(getXMLBool(xmlFile, binding..'#strawOutputFront'),false);
			local bindingAllowFertilization = Utils.getNoNil(getXMLBool(xmlFile, binding..'#allowFertilization'),false);
			local bindingSoilmodN = Utils.getNoNil(getXMLInt(xmlFile, binding..'#soilmodN'),0);
			local bindingSoilmodPK = Utils.getNoNil(getXMLInt(xmlFile, binding..'#soilmodPK'),0);

			if not hasXMLProperty(xmlFile, bindingFruitType) then
				break;
			end;
			ChoppedStraw.strawBindings[bindingFruitType] = {
				strawType = strawType,
				strawTypeFoliageId = strawTypeFoliageId,
				strawOutputFront = bindingStrawOutputFront,
				allowFertilization = bindingAllowFertilization,
				soilmodN = bindingSoilmodN,
				soilmodPK = bindingSoilmodPK
			};
			b = b + 1;
		end;
		a = a + 1;
	end;
end;

--function AddChoppedStraw:tableMap(table, func)
--	local newArray = {};
--	for i,v in ipairs(table) do
--		newArray[i] = func(v);
--	end;
--	return newArray;
--end;
