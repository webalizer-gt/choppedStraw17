-- Chopped Straw
-- Spec for chopped straw left on field
-- by webalizer, www.planet-ls.de

ChoppedStraw = {};
-- "Register" this object in global environment, so other mods can "see" it.
getfenv(0)["ChoppedStraw"] = ChoppedStraw

function ChoppedStraw.prerequisitesPresent(specializations)
    return SpecializationUtil.hasSpecialization(ChoppedStraw, specializations);
end;

function ChoppedStraw:load(xmlFile)
	-- Only activate when chopped-straw "fruits" are available
	if g_currentMission.fruits[FruitUtil.FRUITTYPE_CHOPPEDSTRAW]
	and g_currentMission.fruits[FruitUtil.FRUITTYPE_CHOPPEDRAPE]
	and g_currentMission.fruits[FruitUtil.FRUITTYPE_CHOPPEDMAIZE]
	then
		self.getAreas = ChoppedStraw.getAreas;
		self.wwMinMaxAreas = ChoppedStraw.wwMinMaxAreas;
		self.createCStrawArea = ChoppedStraw.createCStrawArea;
		self.setCStrawArea = ChoppedStraw.setCStrawArea;

		if self.chopperToggleTime ~= nil then
			self.chopperToggleTime = math.max(4000, self.chopperToggleTime)
		end;

		-- Area creation
		self.strawZOffset = -1.5;
		self.strawNodeId = Utils.indexToObject(self.components, getXMLString(xmlFile, "vehicle.workAreas.workArea#startIndex"));

		self.cStrawAreas = {}
		if self.strawNodeId ~= nil then
			self.cStrawAreas = self:createCStrawArea();
		end;
	else
		-- Disable chopped-straw for this vehicle.
		self.strawNodeId = nil;
	end
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
	if not self.isStrawActive
	and self.strawNodeId ~= nil
	and self.lastValidInputFruitType ~= FruitUtil.FRUITTYPE_UNKNOWN
	then
		local fruitDesc = FruitUtil.fruitIndexToDesc[self.lastValidInputFruitType];
    local choppedStrawBinding = ChoppedStraw.strawBindings[fruitDesc.name];

		if self.isTurnedOn
		and self.movingDirection > 0
		and fruitDesc ~= nil
		and choppedStrawBinding.strawOutputFront
		then
			for _,oImplement in pairs(self.attachedImplements) do --parse all implements
				if oImplement ~= nil and oImplement.object ~= nil then
					if oImplement.object.threshingParticleSystems ~= nil and oImplement.object.threshingParticleSystems.isEmitting then
						for _,workArea in pairs(oImplement.object.workAreas) do
							local x, _, z = getWorldTranslation(workArea.start)
							local x1, _, z1 = getWorldTranslation(workArea.width)
							local x2, _, z2 = getWorldTranslation(workArea.height)
							Utils.updateStrawHaulmArea(choppedStrawBinding.strawTypeFoliageId, x, z, x1, z1, x2, z2)
						end;
					end;
				end;
			end;
		elseif self.chopperPSenabled then
			if choppedStrawFoliageId ~= nil then
				for i = 1, table.getn(self.cStrawAreas) do
					local x, _, z = getWorldTranslation(self.cStrawAreas[i].start)
					local x1, _, z1 = getWorldTranslation(self.cStrawAreas[i].width)
					local x2, _, z2 = getWorldTranslation(self.cStrawAreas[i].height)
					Utils.updateStrawHaulmArea(choppedStrawBinding.strawTypeFoliageId, x, z, x1, z1, x2, z2)
				end;
			end;
		end;
	end;
end;

function ChoppedStraw:draw()
end;

function ChoppedStraw:attachImplement(implement)
	if self.strawNodeId ~= nil then
		self.caxMin, self.caxMax, self.cay, self.caz, self.caWW, self.caCenter = self:getAreas();
		self:setCStrawArea();
	end;
end;

function ChoppedStraw:getAreas()
	local wwMin = 0;
	local wwMax = 0;
	local wwY = 0;
	local wwZ = 0;
	for nIndex,oImplement in pairs(self.attachedImplements) do --parse all implements
		if oImplement ~= nil and oImplement.object ~= nil then
			wwMin,wwMax,wwY,wwZ = self:wwMinMaxAreas(self,oImplement.object.workAreas);
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

function ChoppedStraw:wwMinMaxAreas(self,areas)
	local minA = 0;
	local maxA = 0;
	if areas ~= nil then
		for _,cuttingArea in pairs(areas) do
				local x1,y1,z1 = getWorldTranslation(cuttingArea.start)
				local x2,y2,z2 = getWorldTranslation(cuttingArea.width)
				local x3,y3,z3 = getWorldTranslation(cuttingArea.height)
				local lx1,ly1,lz1 = worldToLocal(self.rootNode,x1,y1,z1)
				local lx2,ly2,lz2 = worldToLocal(self.rootNode,x2,y2,z2)
				local lx3,ly3,lz3 = worldToLocal(self.rootNode,x3,y3,z3)

				minA = math.min(minA, lx1, lx2, lx3)
				maxA = math.max(maxA, lx1, lx2, lx3)
		end;
	end;
	return minA, maxA, ly1, lz1;
end;

function ChoppedStraw:createCStrawArea()
	for _,strawArea in pairs(self.workAreas) do
		local x2,y2,z2 = getWorldTranslation(strawArea.width);
		local lx2,ly2,lz2 = worldToLocal(self.rootNode,x2,y2,z2);
		self.strawXOffset = lx2;
	end;

	local cStrawAreas = {};

	local startId1 = createTransformGroup("start1");
	link(self.strawNodeId, startId1);
	local heightId1 = createTransformGroup("height1");
	link(self.strawNodeId, heightId1);
	local widthId1 = createTransformGroup("width1");
	link(self.strawNodeId, widthId1);
	table.insert(cStrawAreas, {foldMinLimit=0,start=startId1,height=heightId1,foldMaxLimit=0.2,width=widthId1});
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
