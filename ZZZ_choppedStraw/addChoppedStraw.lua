--
-- AddChoppedStraw
--
-- @author: webalizer
-- @version: 17.01b
-- @date: 16 Sep 2016
-- @history: 17.01b (16 Sep 2016): initial implementation


AddChoppedStraw = {};
AddChoppedStraw.version = '17.01b';
AddChoppedStraw.author = 'webalizer';

function AddChoppedStraw:loadMap(name)
	if self.initialized then return end;

	local mpath =  name:match("(.+)%/.+")
	print(('loadMap name = %s'):format(mpath));

	local xmlFilePath =  Utils.getFilename('addChoppedStraw.xml', mapDir);
	print(('xmlFilePath = %s'):format(xmlFilePath));
	if fileExists(xmlFilePath) then
		local xmlFile = loadXMLFile('choppedStrawXML', xmlFilePath);
		local key = 'AddChoppedStraw';

		if hasXMLProperty(xmlFile, key) then
				print(('AddChoppedStraw v%s by %s loading...'):format(AddChoppedStraw.version, AddChoppedStraw.author));
				self:registerStrawTypes(xmlFile, key);
			else
				print('Error: missing AddChoppedStraw in addChoppedStraw.xml!');
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

addModEventListener(AddChoppedStraw)
