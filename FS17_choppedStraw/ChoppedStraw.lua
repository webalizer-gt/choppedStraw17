-- choppedStraw
-- Spec for chopped straw left on field
-- by webalizer, www.planet-ls.de

ChoppedStraw = {};

function ChoppedStraw.prerequisitesPresent(specializations)
    return SpecializationUtil.hasSpecialization(ChoppedStraw, specializations);
	--return true;
end;

local debugmode = 10;

function logInfo(mode,message)
	if (mode >= debugmode and mode < 5) then
		print(('%s DEBUG | %s'):format(g_currentMission.cs_version, message));
	elseif mode == 5 then
		print(('%s | %s'):format(g_currentMission.cs_version, message));
	end;
end;

function ChoppedStraw:load(savegame)

	self.getAreas = ChoppedStraw.getAreas;
	self.wwMinMaxAreas = ChoppedStraw.wwMinMaxAreas;
	self.createCStrawArea = ChoppedStraw.createCStrawArea;
	self.setCStrawArea = ChoppedStraw.setCStrawArea;


	if  self.strawToggleTime ~= nil then
		 self.strawToggleTime = math.max(4000,  self.strawToggleTime);
		logInfo(1,('self.strawToggleTime: %s'):format(self.strawToggleTime));
	end;

	-- Area creation
	self.strawZOffset = -1.6;
	self.strawNodeId = Utils.indexToObject(self.components, getXMLString(self.xmlFile, "vehicle.workAreas.workArea#startIndex"));
	logInfo(1,('strawNodeId: %s'):format(self.strawNodeId));

	if self.strawNodeId ~= nil then
		self.cStrawAreas = {}
		self.cStrawAreas = self:createCStrawArea();
		logInfo(1,'CStrawArea created');
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
    -- only run on server, sync. is done automatically
    if self.isServer and g_currentMission.cs_strawBindings ~= nil then
        if not self.isStrawEnabled	and self.strawNodeId ~= nil and self.lastValidInputFruitType ~= FruitUtil.FRUITTYPE_UNKNOWN	then
            local fruitDesc = FruitUtil.fruitIndexToDesc[self.lastValidInputFruitType];
            logInfo(0,('fruitDesc.name: %s'):format(fruitDesc.name));
            local choppedStrawBinding = g_currentMission.cs_strawBindings[fruitDesc.name];
            logInfo(0,('choppedStrawBinding: %s'):format(choppedStrawBinding));
            if choppedStrawBinding ~= nil then
                local strawTypeFoliageId = g_currentMission.cs_strawTypes[choppedStrawBinding.strawTypeId].foliageId
                if  self.movingDirection > 0 and choppedStrawBinding.strawOutputFront and strawTypeFoliageId ~= nil then
                    for object,implement in pairs(self.attachedCutters) do --parse all cutters
                        if object ~= nil then
                            if object.lastCutterAreaBiggerZero then
                                for _,workArea in pairs(object.workAreas) do
                                    local x, _, z = getWorldTranslation(workArea.start);
                                    local x1, _, z1 = getWorldTranslation(workArea.width);
                                    local x2, _, z2 = getWorldTranslation(workArea.height);
                                    logInfo(0,('Arguments to Util.updateStrawHaulmArea: strawTypeFoliageId: %s, x: %s, z: %s, x1: %s, z1: %s, x2: %s, z2: %s'):format(strawTypeFoliageId, x, z, x1, z1, x2, z2));
                                    Utils.updateStrawArea(strawTypeFoliageId, x, z, x1, z1, x2, z2);
                                end;
                            end;
                        end;
                    end;
                elseif self.chopperPSenabled and not choppedStrawBinding.strawOutputFront and strawTypeFoliageId ~= nil then
                    for i = 1, table.getn(self.cStrawAreas) do
                        local x, _, z = getWorldTranslation(self.cStrawAreas[i].start);
                        local x1, _, z1 = getWorldTranslation(self.cStrawAreas[i].width);
                        local x2, _, z2 = getWorldTranslation(self.cStrawAreas[i].height);
                        logInfo(0,('Arguments to Util.updateStrawHaulmArea: strawTypeFoliageId: %s, x: %s, z: %s, x1: %s, z1: %s, x2: %s, z2: %s'):format(strawTypeFoliageId, x, z, x1, z1, x2, z2));
                        Utils.updateStrawArea(strawTypeFoliageId, x, z, x1, z1, x2, z2);
                    end;
                end;
            end;
        end;
    end
end;

function ChoppedStraw:draw()
end;

function ChoppedStraw:onAttachImplement(implement)
	if self.strawNodeId ~= nil then
		--self.caxMin, self.caxMax, self.cay, self.caz, self.caWW, self.caCenter = self:getAreas();
		local caxMin, caxMax, cay, caz, caWW, caCenter = self:getAreas();
		logInfo(1,('caxMin %s, caxMax %s, cay %s, caz %s, caWW %s, caCenter %s'):format(caxMin, caxMax, cay, caz, caWW, caCenter));
		self:setCStrawArea(caxMin, caxMax, cay, caz, caWW, caCenter);
	end;
end;

function ChoppedStraw:getAreas()
	local wwMin = 0;
	local wwMax = 0;
	local wwY = 0;
	local wwZ = 0;

	for object,implement in pairs(self.attachedCutters) do --parse all cutters
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
		logInfo(1,('wwMinMaxAreas: minA: %s, maxA: %s, ly1: %s; lz1: %s'):format(minA, maxA, ly1, lz1));
		return minA, maxA, ly1, lz1;
	end;
end;

function ChoppedStraw:createCStrawArea()
	local combineAreas =  self:getTypedWorkAreas(WorkArea.AREATYPE_COMBINE);
	logInfo(1,('combineAreas: %s'):format(combineAreas));
	for _,strawArea in pairs(combineAreas) do
		local x2,y2,z2 = getWorldTranslation(strawArea.width);
		local lx2,ly2,lz2 = worldToLocal(self.rootNode,x2,y2,z2);
		self.strawXOffset = lx2;
		logInfo(1,('self.strawXOffset: %s'):format(self.strawXOffset));
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

function ChoppedStraw:setCStrawArea(caxMin, caxMax, cay, caz, caWW, caCenter)
	local strawXOffset = self.strawXOffset;
	local strawZOffset = self.strawZOffset;
	local xMin = (caWW/2 + strawXOffset)*-1;
	local xMax = (caWW/2 + strawXOffset);
	local center = caCenter + strawXOffset;
	local y = cay;

	setTranslation(self.cStrawAreas[1].start,center,y,strawZOffset);
	setTranslation(self.cStrawAreas[1].width,xMax,y,strawZOffset -2);
	setTranslation(self.cStrawAreas[1].height,xMin,y,strawZOffset -2);
end;
