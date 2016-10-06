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
		<strawType name="lightStraw" allowFertilization="true" soilmodN="1" soilmodPK="1" >
			<binding fruitType="wheat" strawOutputFront="false" />
			<binding fruitType="barley" strawOutputFront="false" />
		</strawType>
		<strawType name="darkStraw" allowFertilization="true" soilmodN="2" soilmodPK="1" >
			<binding fruitType="rape" strawOutputFront="false" />
		</strawType>
		<strawType name="maizeStraw" allowFertilization="true" soilmodN="2" soilmodPK="2" >
			<binding fruitType="maize" strawOutputFront="true" />
		</strawType>
		<strawType name="soybeanStraw" allowFertilization="false" >
			<binding fruitType="soybean" strawOutputFront="true" />
		</strawType>
		<strawType name="sunflowerStraw" allowFertilization="false">
			<binding fruitType="sunflower" strawOutputFront="true" />
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
				print('Error: missing AddChoppedStraw in modDesc.xml!');
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

	-- iterate over strawType tags
	local a = 0;
	while true do
		local strawTypeKey = key .. ('.strawType(%d)'):format(a);
		if not hasXMLProperty(xmlFile, strawTypeKey) then
			break;
		end;

		local strawTypeName = getXMLString(xmlFile, strawTypeKey..'#name');
		if strawTypeName == nil then
			print(('Error: missing "name" attribute for strawType #%d in "AddChoppedStraw". Adding strawTypes aborted.'):format(a));
			break;
		end;

		-- One of these two, but which one????
		local strawTypeFoliageId = g_currentMission:loadFoliageLayer(strawTypeName, -5, -1, true, "alphaBlendStartEnd");
		--local strawTypeFoliageId = getChild(g_currentMission.terrainRootNode, strawTypeName);

		local strawTypeAllowFertilization = Utils.getNoNil(getXMLBool(xmlFile, strawTypeKey..'#allowFertilization'),false);
		local strawTypeSoilmodN = Utils.getNoNil(getXMLInt(xmlFile, strawTypeKey..'#soilmodN'),0);
		local strawTypeSoilmodPK = Utils.getNoNil(getXMLInt(xmlFile, strawTypeKey..'#soilmodPK'),0);

		if (strawTypeFoliageId == nil or strawTypeFoliageId == 0) then
			print(('Error: missing foliage layer for strawType #%d in "AddChoppedStraw". Adding strawTypes aborted.'):format(a));
			break;
		end;
		-- store values in global ChoppedStraw
		ChoppedStraw.strawTypes[a] = {
			name = strawTypeName,
			foliageId = strawTypeFoliageId,
			allowFertilization = strawTypeAllowFertilization,
			soilmodN = strawTypeSoilmodN,
			soilmodPK = strawTypeSoilmodPK
		};

		-- iterate over bindings
		local b = 0;
		while true do
			local binding = strawTypeKey .. ('.binding(%d)'):format(b);
			if not hasXMLProperty(xmlFile, binding) then
				break;
			end;
			local bindingFruitType = getXMLString(xmlFile, binding..'#fruitType');
			local bindingStrawOutputFront = Utils.getNoNil(getXMLBool(xmlFile, binding..'#strawOutputFront'),false);

			if not hasXMLProperty(xmlFile, bindingFruitType) then
				break;
			end;
			-- store values in global ChoppedStraw, strawTypeId is a reference to strawTypes table >>ChoppedStraw.strawTypes[a]
			ChoppedStraw.strawBindings[bindingFruitType] = {
				strawTypeId = a,
				strawOutputFront = bindingStrawOutputFront,
			};
			b = b + 1;
		end;
		a = a + 1;
	end;
end;
