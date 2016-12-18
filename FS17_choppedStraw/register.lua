-- choppedStraw
-- Spec for chopped straw left on field
-- by webalizer, www.planet-ls.de

SpecializationUtil.registerSpecialization('ChoppedStraw', 'ChoppedStraw', g_currentModDirectory .. 'ChoppedStraw.lua');
local choppedStrawSpec = SpecializationUtil.getSpecialization('ChoppedStraw');

ChoppedStraw_Register = {};
local modItem = ModsUtil.findModItemByModName(g_currentModName);

local function getFoliageLayer(name)
	logInfo(0,('g_currentMission.terrainRootNode = %s, foliageLayerName = %s'):format(g_currentMission.terrainRootNode, name));
    if name ~= nil then
        foliageId = g_currentMission:loadFoliageLayer(name, -5, -1, true, "alphaBlendStartEnd");
        return foliageId;
    end;
    return nil;
end;

ChoppedStraw_Register.initialized = false

function ChoppedStraw_Register:loadMap(name)
	g_currentMission.cs_version = '*** ChoppedStraw v'..((modItem and modItem.version) and modItem.version or "?.?.?");
	g_currentMission.cs_mapPath =  name:match("(.+)%/.+")..'/choppedStraw_SDK/';

	if self.specAdded then return; end;
	logInfo(5,'register specialization');

	local addedTo = {};

	for k, v in pairs(VehicleTypeUtil.vehicleTypes) do
		if v ~= nil then
			-- has Combine spec -> continue
			local allowInsertion = SpecializationUtil.hasSpecialization(Combine, v.specializations) and not SpecializationUtil.hasSpecialization(FruitPreparer, v.specializations);

			--local customEnvironment;
			if allowInsertion then
				logInfo(1,('    vehicleType %q has Combine spec'):format(v.name));
				if v.name:find('.') then
					customEnvironment = Utils.splitString('.', v.name)[1];
					logInfo(1,('      customEnvironment=%q'):format(customEnvironment));
				end;

				if customEnvironment then
					-- has ChoppedStraw spec -> abort
					if rawget(SpecializationUtil.specializations, customEnvironment .. '.ChoppedStraw') ~= nil or rawget(SpecializationUtil.specializations, customEnvironment .. '.choppedStraw') ~= nil then
						logInfo(1,('      already has spec "ChoppedStraw" -> allowInsertion = false'));
						allowInsertion = false;
					end;
				end;
			end;

			if allowInsertion then
				logInfo(1,('        specialization added to %q'):format(v.name));
				table.insert(v.specializations, choppedStrawSpec);
				addedTo[#addedTo + 1] = v.name;
			end;
		end;
	end;

	if #addedTo > 0 then
		logInfo(5,('specialization added to %s vehicle types'):format(#addedTo));
	end;

	self.specAdded = true;

end;

original_loadMission00Finished = Mission00.loadMission00Finished;
Mission00.loadMission00Finished = function(self, node, arguments)
    original_loadMission00Finished(self, node, arguments);

    if g_currentMission.densityMapSyncer ~= nil then
        local mapPath = g_currentMission.cs_mapPath;
        logInfo(1,('loadMap name = %s'):format(mapPath));

        local xmlFilePath =  Utils.getFilename('addChoppedStraw.xml', mapPath);
        logInfo(1,('xmlFilePath = %s'):format(xmlFilePath));
        if fileExists(xmlFilePath) then
            local csFile = loadXMLFile('choppedStrawXML', xmlFilePath);
            local key = 'AddChoppedStraw';

            if hasXMLProperty(csFile, key) then
                logInfo(5,'loading straw types');
                ChoppedStraw_Register:registerStrawTypes(csFile, key);
				
				local fruitString = "";
				for key,entry in pairs(g_currentMission.cs_strawBindings) do
					if g_currentMission.cs_strawTypes[entry.strawTypeId].allowFertilization then
						fruitString = fruitString..key.." ";
					end;
				end;
				if g_currentMission.cs_globalFertilization then
					logInfo(5,('fertilizing fruittypes: %s'):format(fruitString));
				else
					logInfo(5,('fertilization disabled on this map!'));
				end;
                logInfo(5,('loaded %s straw types'):format(#g_currentMission.cs_strawTypes+1));
            else
                logInfo(5,('Error: missing AddChoppedStraw in %s!'):format(xmlFilePath));
            end; -- END hasXMLProperty(csFile, key)
            delete(csFile);
			-- If SoilMod-v2.x does not exist then do it "the old way"...
			--if modSoilMod2 == nil then
				ChoppedStraw_Register.old_updatePloughArea = Utils.updatePloughArea;
				Utils.updatePloughArea = ChoppedStraw_Register.updatePloughArea;

				ChoppedStraw_Register.old_updateCultivatorArea = Utils.updateCultivatorArea;
				Utils.updateCultivatorArea = ChoppedStraw_Register.updateCultivatorArea;
			--end;
        else
            logInfo(5,('config file %s not found. ChoppedStraw not available on this map!'):format(xmlFilePath));
        end; -- END fileExists(xmlFilePath)

    end;
end;

function ChoppedStraw_Register:registerStrawTypes(csFile, key)
	-- Read straw informations into g_currentMission.cs_globalFertilization
	-- Use fertilization in general? (default=true)
	if hasXMLProperty(csFile, key..'#globalFertilization') then
		g_currentMission.cs_globalFertilization = Utils.getNoNil(getXMLBool(csFile, key..'#globalFertilization'),true);
	end;

	-- iterate over strawType tags
	g_currentMission.cs_strawTypes = {};
	g_currentMission.cs_strawBindings = {};
	local a = 0;
	while true do
		local strawTypeKey = key .. ('.strawType(%d)'):format(a);
		if not hasXMLProperty(csFile, strawTypeKey) then
			break;
		end;

		local strawTypeName = getXMLString(csFile, strawTypeKey..'#name');
		if strawTypeName == nil then
			logInfo(5,('Error: missing "name" attribute for strawType #%d in "AddChoppedStraw". Adding strawTypes aborted!'):format(a));
			break;
		end;

		local strawTypeFoliageId = getFoliageLayer(strawTypeName);

		local strawTypeAllowFertilization = Utils.getNoNil(getXMLBool(csFile, strawTypeKey..'#allowFertilization'),false);
		local strawTypeSoilmodN = Utils.getNoNil(getXMLInt(csFile, strawTypeKey..'#soilmodN'),0);
		local strawTypeSoilmodPK = Utils.getNoNil(getXMLInt(csFile, strawTypeKey..'#soilmodPK'),0);

		if (strawTypeFoliageId == nil or strawTypeFoliageId == 0) then
			logInfo(5,('Error: missing foliage layer for strawType #%d %s. Adding strawTypes aborted!'):format(a, strawTypeName));
			break;
		end;

		-- register layer in syncer
		addDensityMapSyncerDensityMap(g_currentMission.densityMapSyncer, strawTypeFoliageId);

		-- store values in g_currentMission._
		logInfo(1,('g_currentMission.cs_strawType[%s]: name: %s | foliageId: %s | allowFertilization: %s | soilModN: %s | soilModPK: %s'):format(a, strawTypeName, strawTypeFoliageId, strawTypeAllowFertilization, strawTypeSoilmodN, strawTypeSoilmodPK));

		g_currentMission.cs_strawTypes[a] = {
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
			if not hasXMLProperty(csFile, binding) then
				break;
			end;
			local bindingFruitType = getXMLString(csFile, binding..'#fruitType');
			local bindingStrawOutputFront = Utils.getNoNil(getXMLBool(csFile, binding..'#strawOutputFront'),false);

			-- store values in g_currentMission._, strawTypeId is a reference to strawTypes table >>g_currentMission.cs_strawTypes[a]
			logInfo(1,('     g_currentMission.cs_strawBindings[%s]: strawTypeId: %s | strawOutputFront: %s'):format(bindingFruitType, a, bindingStrawOutputFront));

			g_currentMission.cs_strawBindings[bindingFruitType] = {
				strawTypeId = a,
				strawOutputFront = bindingStrawOutputFront,
			};
			b = b + 1;
		end;
		a = a + 1;
	end;
end;

function ChoppedStraw_Register.updateCultivatorArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, forced, commonForced, angle)
	ChoppedStraw_Register.processStrawArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ)
	local realArea, area = ChoppedStraw_Register.old_updateCultivatorArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, forced, commonForced, angle);
	return realArea, area;
end;

function ChoppedStraw_Register.updatePloughArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, forced, commonForced, angle)
	ChoppedStraw_Register.processStrawArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ);
	local realArea, area = ChoppedStraw_Register.old_updatePloughArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ, forced, commonForced, angle);
	return realArea, area;
end;

function ChoppedStraw_Register.processStrawArea(startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ)
    local x, z, widthX, widthZ, heightX, heightZ = Utils.getXZWidthAndHeight(nil, startWorldX, startWorldZ, widthWorldX, widthWorldZ, heightWorldX, heightWorldZ);
	local detailId = g_currentMission.terrainDetailId;
    -- iterate over strawTypes
    for _,entry in pairs(g_currentMission.cs_strawTypes) do
        if entry.allowFertilization and g_currentMission.cs_globalFertilization then
			logInfo(0,('entry.allowFertilization: %s'):format(entry.allowFertilization));
			logInfo(0,('entry.foliageId: %s'):format(entry.foliageId));
            setDensityMaskParams(entry.foliageId, "greater", 0);
             -- increase spray level
            addDensityMaskedParallelogram(detailId, x,z, widthX,widthZ, heightX,heightZ, g_currentMission.sprayLevelFirstChannel, g_currentMission.sprayLevelNumChannels, entry.foliageId, 0, 1, 1);
            -- set visible spray level
            setDensityMaskedParallelogram(detailId, x,z, widthX,widthZ, heightX,heightZ, g_currentMission.sprayFirstChannel, g_currentMission.sprayNumChannels, entry.foliageId, 0, 1, 0);
            setDensityMaskParams(entry.foliageId, "greater", 0);
        end;
        -- remove layer
        setDensityParallelogram(entry.foliageId, x,z, widthX,widthZ, heightX,heightZ, 0, 1, 0)
    end;
end;

Utils.updateStrawArea = function(choppedStrawFoliageId, x, z, x1, z1, x2, z2)

	local detailId = g_currentMission.terrainDetailId;
	local x, z, widthX, widthZ, heightX, heightZ = Utils.getXZWidthAndHeight(nil, x, z, x1, z1, x2, z2);

	setDensityCompareParams(detailId, "greater", 0);
	local density, area, _ = getDensityParallelogram(detailId, x,z, widthX,widthZ, heightX,heightZ, g_currentMission.terrainDetailTypeFirstChannel, g_currentMission.terrainDetailTypeNumChannels);
	setDensityCompareParams(detailId, "greater", -1);
	local terrainValue = 10;
	if area > 0 then
		terrainValue = math.floor(density/area + 0.5);
    end;
	if terrainValue < 5 then
		setDensityMaskedParallelogram(choppedStrawFoliageId, x, z, widthX, widthZ, heightX, heightZ, 0, 1, g_currentMission.terrainDetailId, g_currentMission.terrainDetailTypeFirstChannel, g_currentMission.terrainDetailTypeNumChannels, 1)
	end;
end;

function ChoppedStraw_Register:update(dt)end;
function ChoppedStraw_Register:deleteMap() end;
function ChoppedStraw_Register:keyEvent(unicode, sym, modifier, isDown) end;
function ChoppedStraw_Register:mouseEvent(posX, posY, isDown, isUp, button) end;
function ChoppedStraw_Register:draw() end;

addModEventListener(ChoppedStraw_Register);
