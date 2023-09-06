function DBD_AwardAchivement(name,desc,icon)
    local scr = game.Players.LocalPlayer.PlayerGui.BadgeObtainUI.BadgeObtainHandler
    L_Holder_2 = scr.Parent.Holder
    local settings = {name,desc,icon}
    local S_TweenService_1 = game:GetService("TweenService")
    scr.Sound:Play()
    L_Holder_2.Position = UDim2.new(1, 10, 0, 10)
    L_Holder_2.BadgeName.Text = settings[1]
    L_Holder_2.Icon.Image = "rbxassetid://"..tostring(settings[3])
    L_Holder_2.Icon.Border.Color = Color3.fromRGB(255, 255, 255)
    L_Holder_2.BadgeDescription.Text = settings[2]
    L_Holder_2.Visible = true
    S_TweenService_1:Create(L_Holder_2, TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Position = UDim2.new(1, -210, 0, 10)}):Play()
    task.wait(6)
    S_TweenService_1:Create(L_Holder_2, TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Position = UDim2.new(1, 10, 0, 10)}):Play()
    task.wait(1)
    L_Holder_2.Visible = false
end

function DBD_DieBasic()
    fireclickdetector(workspace.TestDeath.ClickDetector)
end

function DBD_GetRush()
    return workspace.ActiveEntities:FindFirstChild("Rush")
end

function DBD_GetAmbush()
    return workspace.ActiveEntities:FindFirstChild("Ambush")
end

function DBD_GetSeek()
    return workspace.ActiveEntities:FindFirstChild("Seek")
end

function DBD_GetFigure()
    return workspace.ActiveEntities:FindFirstChild("Figure")
end

local inside_DoorOpened = Instance.new("BindableEvent")
DBD_DoorOpened = inside_DoorOpened.Event
workspace.CurrentRoom.Changed:Connect(function(value)
    local segments = workspace.Segments:GetChildren()
    table.sort(segments, function(a,b)
        if a:FindFirstChild("SegmentNumValue") and b:FindFirstChild("SegmentNumValue") then
            return tonumber(a.SegmentNumValue.Value+1) < tonumber(b.SegmentNumValue.Value+1)
        else
            return false
        end
    end)
    inside_DoorOpened:Fire(value,segments[value])
end)                              

DBD_Templates = { 
    Rush = {Model = game.ReplicatedStorage.Entities.Rush,PlaySounds = {"Distant","Near"},Wobble = true,Speed = 1,Kills = true,Rebound = false},
    Ambush = {Model = game.ReplicatedStorage.Entities.Ambush,PlaySounds = {"Static","Near"},Wobble = false,Speed = 1,Kills = true,Rebound = {2,6}},
}

function DBD_SpawnRushlike(settings) -- Model model, PlaySounds {Sound}, Wobble true/false, Speed number, Kills true/false, Rebound {min,max},
    --Events: OnTouch (hiding true/false)
    local rushclone = settings.Model:Clone()
    --local events = {Instance.new("BindableEvent",Parent = rushclone)}
    
    task.spawn(function(settings)
        
        rushclone.Parent = workspace.ActiveEntities
        local points={} --table of part points to go through in order
        local movePart=rushclone --rush/ambush part
    
        print("Playing PlaySounds")
    
        if settings.PlaySounds then
            local Children = rushclone:GetChildren()
            for i=1,#Children do
                if table.find(settings.PlaySounds,Children[i].Name) then
                    Children[i]:Play()
                end
            end
        end
    
        print("Wobbling PlaySounds")
    
        if settings.Wobble == nil then
            settings.Wobble = false
        end
    
        if settings.Wobble then --Basically only vanilla rush uses this, otherwise useless
            task.spawn(function()
                while true do
                    if rushclone then
                        movePart.Distant.SoundGroup.Pitch.Octave = math.random(50,70)/100
                    end
                    wait(0.4)
                end
            end)
        end
        
        print("Getting The Moves")
        
        local segments = workspace.Segments:GetChildren()
        table.sort(segments, function(a,b)
            if a:FindFirstChild("SegmentNumValue") and b:FindFirstChild("SegmentNumValue") then
                return tonumber(a.SegmentNumValue.Value+1) < tonumber(b.SegmentNumValue.Value+1)
            else
                return false
            end
        end)
        iSTART = workspace.CurrentRoom.Value-10
        if iSTART < 1 then
            iSTART = 1
        end
        for i=iSTART,#segments do
            print(segments[i].Name)
            if segments[i]:FindFirstChild("RushPoints") then
                local temp = segments[i].RushPoints:GetChildren()
                table.sort(temp, function(a,b)
                    return tonumber(a.Name) < tonumber(b.Name)
                end)
                for i=1,#temp do
                    points[#points+1] = temp[i].CFrame.Position
                end
            end
            points[#points+1] = segments[i].Exit.Main.CFrame.Position
        end
        
        
    
        print("Moving The Moves & Killing The Players")
    
        if settings.Kills == nil then
            settings.Kills = false
        end
    
        task.spawn(function()
            while rushclone.Parent == workspace.ActiveEntities do
                wait()
                local rayOrigin = rushclone.Position
                local rayDirection = CFrame.lookAt(rayOrigin,game.Players.LocalPlayer.Character.Head.Position).LookVector * 15
            
                rushclone.CFrame = CFrame.lookAt(rayOrigin,game.Players.LocalPlayer.Character.Head.Position) 
            
                local raycastParams = RaycastParams.new()
                raycastParams.FilterDescendantsInstances = {rush}
                raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
                raycastParams.RespectCanCollide = true
            
                local raycastResult = workspace:Raycast(rayOrigin, rayDirection,raycastParams)
            
                if raycastResult then
                    if raycastResult.Instance.Parent:FindFirstChild("Humanoid") and raycastResult.Instance.Parent == game.Players.LocalPlayer.Character then
                        if not game.Players.LocalPlayer:GetAttribute("Hidden") then
                            if not settings.Kills then
                                return DBD_DieBasic()
                            end
                            
                        end
                        --events[1]:Fire(game.Players.LocalPlayer:GetAttribute("Hidden"))
                    end
                else
                        
                end
            end
        end)
    
        if settings.Speed == nil then
            settings.Speed = 1
        end
        
        local speed=60*settings.Speed
        
        local tweenService=game:GetService("TweenService")
        rushclone.CFrame=CFrame.new(points[1])
        if not settings.Rebound then
            for i,v in pairs(points) do
              local d=(rushclone.CFrame.Position-v).Magnitude
              local t=d/speed
               tweenService:Create(rushclone,TweenInfo.new(t,Enum.EasingStyle.Linear),{CFrame=CFrame.new(v)}):Play()
              task.wait(t)
            end
        else
            for r=1,math.random(settings.Rebound[1],settings.Rebound[2]) do
                for i=1,#points do
                    v = points[i]
                    local d=(rushclone.CFrame.Position-v).Magnitude
                    local t=d/speed
                    tweenService:Create(rushclone,TweenInfo.new(t,Enum.EasingStyle.Linear),{CFrame=CFrame.new(v)}):Play()
                    task.wait(t)
                end
                for i=1,#points do
                    v = points[#points-(i-1)]
                    local d=(rushclone.CFrame.Position-v).Magnitude
                    local t=d/speed
                    tweenService:Create(rushclone,TweenInfo.new(t,Enum.EasingStyle.Linear),{CFrame=CFrame.new(v)}):Play()
                    task.wait(t)
                end
            end
        end
        
        rushclone:Destroy()
    end)
    return events
end
