-- Chopped Straw
-- Spec for chopped straw left on field
-- by webalizer, www.planet-ls.de

ChoppedStraw = {};
-- "Register" this object in global environment, so other mods can "see" it.
getfenv(0)["ChoppedStraw"] = ChoppedStraw

function ChoppedStraw.prerequisitesPresent(specializations)
    return SpecializationUtil.hasSpecialization(ChoppedStraw, specializations);
	--return true;
end;

local debugmode = true;

local function messagePrint(mode,message)
	if (debugmode and mode == 1) then
		print(('%s DEBUG | %s'):format(ChoppedStraw.version, message));
	elseif mode == 2 then
		print(('%s | %s'):format(ChoppedStraw.version, message));
	end;
end;

local function hasFoliageLayer(foliageId)
    return (foliageId ~= nil and foliageId ~= 0);
end;

local function getFoliageLayer(name)
	 --messagePrint(1,('g_currentMission.terrainRootNode = %s, foliageLayerName = %s'):format(g_currentMission.terrainRootNode, name));
    local foliageId = getChild(g_currentMission.terrainRootNode, name);
    if hasFoliageLayer(foliageId) then
        foliageId = g_currentMission:loadFoliageLayer(name, -5, -1, true, "alphaBlendStartEnd");
        return foliageId;
    end;
    return nil;
end;

function ChoppedStraw:load(savegame)

	self.getAreas = ChoppedStraw.getAreas;
	self.wwMinMaxAreas = ChoppedStraw.wwMinMaxAreas;
	self.createCStrawArea = ChoppedStraw.createCStrawArea;
	self.setCStrawArea = ChoppedStraw.setCStrawArea;
	self.registerStrawTypes = ChoppedStraw.registerStrawTypes;
	
	if self.initialized then return end;
	local mapPath = g_currentMission.mapPath;
	messagePrint(1,('loadMap name = %s'):format(mapPath));

	local xmlFilePath =  Utils.getFilename('addChoppedStraw.xml', mapPath);
	messagePrint(1,('xmlFilePath = %s'):format(xmlFilePath));
	if fileExists(xmlFilePath) then
		local csFile = loadXMLFile('choppedStrawXML', xmlFilePath);
		local key = 'AddChoppedStraw';

		if hasXMLProperty(csFile, key) then
				messagePrint(2,'loading straw types');
				self:registerStrawTypes(csFile, key);
			else
				messagePrint(2,('Error: missing AddChoppedStraw in %s!'):format(xmlFilePath));
		end; -- END hasXMLProperty(csFile, key)
		delete(csFile);
	else
		messagePrint(2,('config file %s not found!'):format(xmlFilePath));
	end; -- END fileExists(xmlFilePath)

	self.initialized = true;

	
	if  self.strawToggleTime ~= nil then
		 self.strawToggleTime = math.max(4000,  self.strawToggleTime);
		messagePrint(1,('self.strawToggleTime: %s'):format(self.strawToggleTime));
	end;

	-- Area creation
	self.strawZOffset = -1.5;
	self.strawNodeId = Utils.indexToObject(self.components, getXMLString(self.xmlFile, "vehicle.workAreas.workArea#startIndex"));
	messagePrint(1,('strawNodeId: %s'):format(self.strawNodeId));

	if self.strawNodeId ~= nil then
		self.cStrawAreas = {}
		self.cStrawAreas = self:createCStrawArea();
		messagePrint(1,'CStrawArea created');
	else
		--Disable chopped-straw for this vehicle.
		self.strawNodeId = nil;
	  end;
end;

function ChoppedStraw:delete()
end;

function ChoppedStraw:readStream(streamId, connection)
end;

function ChoppedStraw:writeStream(streamId, connection)
end;

function ChoppedStraw:mouseEvent(posX, posY, isDown, isUp, button)
end;

function ChoppedStraw:keyEvent(unicode, sym, modifier, isDown)
end;

function ChoppedStraw:onLeave()
end

function ChoppedStraw:update(dt)
end;

function ChoppedStraw:updateTick(dt)
	if not self.isStrawEnabled	and self.strawNodeId ~= nil and self.lastValidInputFruitType ~= FruitUtil.FRUITTYPE_UNKNOWN	then
		local fruitDesc = FruitUtil.fruitIndexToDesc[self.lastValidInputFruitType];
		messagePrint(1,('fruitDesc.name: %s'):format(fruitDesc.name));
		local choppedStrawBinding = ChoppedStraw.strawBindings[fruitDesc.name];
		messagePrint(1,('choppedStrawBinding: %s'):format(choppedStrawBinding));

		if choppedStrawBinding ~= nil then
		  local strawTypeFoliageId = ChoppedStraw.strawTypes[choppedStrawBinding.strawTypeId].foliageId
			if self.isTurnedOn
			and self.movingDirection > 0
			and fruitDesc ~= nil
			and choppedStrawBinding.strawOutputFront
			then
				for object,implement in pairs(self.attachedCutters) do --parse all cutters
					if object ~= nil then
						if object.threshingParticleSystems ~= nil and object.threshingParticleSystems.isEmitting then
							for _,workArea in pairs(object.workAreas) do
								local x, _, z = getWorldTranslation(workArea.start);
								local x1, _, z1 = getWorldTranslation(workArea.width);
								local x2, _, z2 = getWorldTranslation(workArea.height);
								messagePrint(1,('Arguments to Util.updateStrawHaulmArea: strawTypeFoliageId: %s, x: %s, z: %s, x1: %s, z1: %s, x2: %s, z2: %s'):format(strawTypeFoliageId, x, z, x1, z1, x2, z2));
								Utils.updateStrawArea(strawTypeFoliageId, x, z, x1, z1, x2, z2);
							end;
						end;
					end;
				end;
			elseif self.chopperPSenabled then
				if strawTypeFoliageId ~= nil then
					for i = 1, table.getn(self.cStrawAreas) do
						local x, _, z = getWorldTranslation(self.cStrawAreas[i].start);
						local x1, _, z1 = getWorldTranslation(self.cStrawAreas[i].width);
						local x2, _, z2 = getWorldTranslation(self.cStrawAreas[i].height);
						messagePrint(1,('Arguments to Util.updateStrawHaulmArea: strawTypeFoliageId: %s, x: %s, z: %s, x1: %s, z1: %s, x2: %s, z2: %s'):format(strawTypeFoliageId, x, z, x1, z1, x2, z2));	Utils.updateStrawArea(strawTypeFoliageId, x, z, x1, z1, x2, z2);
					end;
				end;
			end;
		end;
	end;
end;

function ChoppedStraw:draw()
end;

function ChoppedStraw:onAttachImplement(implement)
	if self.strawNodeId ~= nil then
		self.caxMin, self.caxMax, self.cay, self.caz, self.caWW, self.caCenter = self:getAreas();
		messagePrint(1,('self.caxMin %s, self.caxMax %s, self.cay %s, self.caz %s, self.caWW %s, self.caCenter %s'):format(self.caxMin, self.caxMax, self.cay, self.caz, self.caWW, self.caCenter));
		self:setCStrawArea();
	end;
end;

function ChoppedStraw:getAreas()
	local wwMin = 0;
	local wwMax = 0;
	local wwY = 0;
	local wwZ = 0;
	
	for object,implement in pairs(self.attachedCutters) do --parse all icutters
		if object ~= nil then
			for _,workArea in pairs(object.workAreas) do
				wwMin,wwMax,wwY,wwZ = self:wwMinMaxAreas(self, workArea);
			end;
		end;
	end;
	
	local workWidth = math.abs(wwMax-wwMin);
	local wwCenter = 0;
	if workWidth > .1 then
		wwCenter = (wwMin+wwMax)/2;
		if math.abs(wwCenter) < 0.1 then
			wwCenter = 0;
		end;
	end;
	return wwMin,wwMax,wwY,wwZ,workWidth,wwCenter;
end;

function ChoppedStraw:wwMinMaxAreas(self, workArea)
	local minA = 0;
	local maxA = 0;
	if workArea ~= nil then
		local x1,y1,z1 = getWorldTranslation(workArea.start)
		local x2,y2,z2 = getWorldTranslation(workArea.width)
		local x3,y3,z3 = getWorldTranslation(workArea.height)
		local lx1,ly1,lz1 = worldToLocal(self.rootNode,x1,y1,z1)
		local lx2,ly2,lz2 = worldToLocal(self.rootNode,x2,y2,z2)
		local lx3,ly3,lz3 = worldToLocal(self.rootNode,x3,y3,z3)
		minA = math.min(minA, lx1, lx2, lx3)
		maxA = math.max(maxA, lx1, lx2, lx3)
		messagePrint(1,('wwMinMaxAreas: minA: %s, maxA: %s, ly1: %s; lz1: %s'):format(minA, maxA, ly1, lz1));
		return minA, maxA, ly1, lz1;
	end;
end;

function ChoppedStraw:createCStrawArea()
	local combineAreas =  self:getTypedWorkAreas(WorkArea.AREATYPE_COMBINE);
	messagePrint(1,('combineAreas: %s'):format(combineAreas));
	for _,strawArea in pairs(combineAreas) do
		local x2,y2,z2 = getWorldTranslation(strawArea.width);
		local lx2,ly2,lz2 = worldToLocal(self.rootNode,x2,y2,z2);
		self.strawXOffset = lx2;
		messagePrint(1,('self.strawXOffset: %s'):format(self.strawXOffset));
	end;

	local cStrawAreas = {};

	local startId1 = createTransformGroup("start1");
	link(self.strawNodeId, startId1);
	local heightId1 = createTransformGroup("height1");
	link(self.strawNodeId, heightId1);
	local widthId1 = createTransformGroup("width1");
	link(self.strawNodeId, widthId1);
	table.insert(cStrawAreas, {start=startId1,width=widthId1,height=heightId1});
	return cStrawAreas;
end;

function ChoppedStraw:setCStrawArea()
	local xMin = (self.caWW/2 + self.strawXOffset)*-1;
	local xMax = (self.caWW/2 + self.strawXOffset);
	local center = self.caCenter + self.strawXOffset;
	local y = self.cay;

	setTranslation(self.cStrawAreas[1].start,center,y,self.strawZOffset);
	setTranslation(self.cStrawAreas[1].width,xMax,y,self.strawZOffset -2);
	setTranslation(self.cStrawAreas[1].height,xMin,y,self.strawZOffset -2);
end;

function ChoppedStraw:registerStrawTypes(csFile, key)
	-- Read straw informations into ChoppedStraw globalFertilization
	-- Use fertilization in general? (default=true)
	if hasXMLProperty(csFile, key..'#globalFertilization') then
		ChoppedStraw.globalFertilization = Utils.getNoNil(getXMLBool(csFile, key..'#globalFertilization'),true);
	end;

	-- iterate over strawType tags
	ChoppedStraw.strawTypes = {};
	ChoppedStraw.strawBindings = {};
	local a = 0;
	while true do
		local strawTypeKey = key .. ('.strawType(%d)'):format(a);
		if not hasXMLProperty(csFile, strawTypeKey) then
			break;
		end;

		local strawTypeName = getXMLString(csFile, strawTypeKey..'#name');
		if strawTypeName == nil then
			messagePrint(2,('Error: missing "name" attribute for strawType #%d in "AddChoppedStraw". Adding strawTypes aborted!'):format(a));
			break;
		end;

		-- One of these two, but which one????
		local strawTypeFoliageId = getFoliageLayer(strawTypeName);

		local strawTypeAllowFertilization = Utils.getNoNil(getXMLBool(csFile, strawTypeKey..'#allowFertilization'),false);
		local strawTypeSoilmodN = Utils.getNoNil(getXMLInt(csFile, strawTypeKey..'#soilmodN'),0);
		local strawTypeSoilmodPK = Utils.getNoNil(getXMLInt(csFile, strawTypeKey..'#soilmodPK'),0);

		if (strawTypeFoliageId == nil or strawTypeFoliageId == 0) then
			messagePrint(2,('Error: missing foliage layer for strawType #%d %s. Adding strawTypes aborted!'):format(a, strawTypeName));
			break;
		end;
		-- store values in global ChoppedStraw
		messagePrint(1,('ChoppedStraw.strawType[%s]: name: %s | foliageId: %s | allowFertilization: %s | soilModN: %s | soilModPK: %s'):format(a, strawTypeName, strawTypeFoliageId, strawTypeAllowFertilization, strawTypeSoilmodN, strawTypeSoilmodPK));

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
			if not hasXMLProperty(csFile, binding) then
				break;
			end;
			local bindingFruitType = getXMLString(csFile, binding..'#fruitType');
			local bindingStrawOutputFront = Utils.getNoNil(getXMLBool(csFile, binding..'#strawOutputFront'),false);

			--if not hasXMLProperty(csFile, bindingFruitType) then
			--	break;
			--end;
			-- store values in global ChoppedStraw, strawTypeId is a reference to strawTypes table >>ChoppedStraw.strawTypes[a]
			messagePrint(1,('     ChoppedStraw.strawBindings[%s]: strawTypeId: %s | strawOutputFront: %s'):format(bindingFruitType, a, bindingStrawOutputFront));

			ChoppedStraw.strawBindings[bindingFruitType] = {
				strawTypeId = a,
				strawOutputFront = bindingStrawOutputFront,
			};
			b = b + 1;
		end;
		a = a + 1;
	end;
end;
