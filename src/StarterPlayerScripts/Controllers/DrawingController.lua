local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local StarterGui = game:GetService("StarterGui")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local DrawMenu = PlayerGui:WaitForChild("DrawMenu.V3")
local Hud = PlayerGui:WaitForChild("HUD.V1")
local DrawButton = Hud:WaitForChild("Frame"):WaitForChild("DrawButton"):WaitForChild("Button")
local DrawButtonFrame = Hud:WaitForChild("Frame"):WaitForChild("DrawButton")
local MainFrame = DrawMenu:WaitForChild("Frame")
local Tools = MainFrame:WaitForChild("Tools")
local MorphButtonFrame = Tools:WaitForChild("MorphButton")
local MorphButton = MorphButtonFrame:WaitForChild("Button")
local Colors = Tools:WaitForChild("Colors")
local ClearCanvasFrame = Tools:WaitForChild("ClearButton")
local ClearCanvasButton = ClearCanvasFrame:WaitForChild("Button")
local EraseButtonFrame = Tools:WaitForChild("EraserButton")
local EraserButton = EraseButtonFrame:WaitForChild("Button")
local ShopButton = Colors:WaitForChild("Shop"):WaitForChild("Button")
local CloseButtonFrame = MainFrame:WaitForChild("CloseButton")
local CloseButton = CloseButtonFrame:WaitForChild("Button")
local ClearConfirmFrame = Tools:WaitForChild("ClearConfirmButton")
local ClearConfirmButton = ClearConfirmFrame:WaitForChild("Button")
local SaveButtonFrame = Tools:WaitForChild("SaveButton")
local SaveButton = SaveButtonFrame:WaitForChild("Button")
local SettingsButtonFrame = Tools:WaitForChild("Settings")
local SettingsButton = SettingsButtonFrame:WaitForChild("Button")
local RoleplayNameFrame = Tools:WaitForChild("RoleplayName")
local RoleplayNameTextBox = RoleplayNameFrame:WaitForChild("TextBox")
local PixelsFrame = MainFrame:WaitForChild("Pixels")
local PixelTemplate = PixelsFrame:WaitForChild("PixelTemplate")
local PixelUIGridLayout = PixelsFrame:WaitForChild("UIGridLayout")

local CurrentCamera = workspace.CurrentCamera

local DrawingRemotes = ReplicatedStorage:WaitForChild("DrawingRemotes")
local MorphRemote = DrawingRemotes:WaitForChild("Morph")
local OnDrawingMenuOpened = DrawingRemotes:WaitForChild("OnDrawingMenuOpened")
local OnDrawingMenuClosed = DrawingRemotes:WaitForChild("OnDrawingMenuClosed")

local DrawingSettingsBindables = ReplicatedStorage:WaitForChild("DrawingSettingsBindables")
local GetDrawingSetting = DrawingSettingsBindables:WaitForChild("GetDrawingSetting")
local OnBrushSizeChanged = DrawingSettingsBindables:WaitForChild("OnBrushSizeChanged")
local OnGridSizeChanged = DrawingSettingsBindables:WaitForChild("OnGridSizeChanged")
local OnDragToDrawStateChanged = DrawingSettingsBindables:WaitForChild("OnDragToDrawStateChanged")

local ColorShopController = require(script.Parent:WaitForChild("ColorShopController"))
local Utilities = script.Parent.Parent:WaitForChild("Utilities")
local Constants = ReplicatedStorage:WaitForChild("Constants")
local GameplayConstants = require(Constants:WaitForChild("Gameplay"))
local UIUtility = require(Utilities:WaitForChild("UserInterface"))
local InterfaceSound = require(Utilities:WaitForChild("InterfaceSound"))
local BrushObject = require(Utilities:WaitForChild("Brush"))

local Drawing = require(ReplicatedStorage:WaitForChild("Drawings"):WaitForChild("Drawing"))
local Grid = require(ReplicatedStorage:WaitForChild("SharedUtilities"):WaitForChild("Grid"))
local Serialization = require(ReplicatedStorage:WaitForChild("SharedUtilities"):WaitForChild("Serialization"))

local TweenFrames = {
    {
        ["Frame"] = CloseButtonFrame,
        ["Button"] = CloseButton,
        ["RegularFrameSize"] = CloseButtonFrame.Size,
        ["EnlargedFrameSize"] = UIUtility.CalculateSizePercentage(20, CloseButtonFrame)
    },
    {
        ["Frame"] = DrawButtonFrame,
        ["Button"] = DrawButton,
        ["RegularFrameSize"] = DrawButtonFrame.Size,
        ["EnlargedFrameSize"] = UIUtility.CalculateSizePercentage(10, DrawButtonFrame)
    },
    {
        ["Frame"] = ClearCanvasFrame,
        ["Button"] = ClearCanvasButton,
        ["RegularFrameSize"] = ClearCanvasFrame.Size,
        ["EnlargedFrameSize"] = UIUtility.CalculateSizePercentage(3, ClearCanvasFrame)
    },
    {
        ["Frame"] = EraseButtonFrame,
        ["Button"] = EraserButton,
        ["RegularFrameSize"] = EraseButtonFrame.Size,
        ["EnlargedFrameSize"] = UIUtility.CalculateSizePercentage(5, EraseButtonFrame)
    },
    {
        ["Frame"] = MorphButtonFrame,
        ["Button"] = MorphButton,
        ["RegularFrameSize"] = MorphButtonFrame.Size,
        ["EnlargedFrameSize"] = UIUtility.CalculateSizePercentage(3, MorphButtonFrame)
    },
    {
        ["Frame"] = SaveButtonFrame,
        ["Button"] = SaveButton,
        ["RegularFrameSize"] = SaveButtonFrame.Size,
        ["EnlargedFrameSize"] = UIUtility.CalculateSizePercentage(5, SaveButtonFrame)
    },
    {
        ["Frame"] = SettingsButtonFrame,
        ["Button"] = SettingsButton,
        ["RegularFrameSize"] = SettingsButtonFrame.Size,
        ["EnlargedFrameSize"] = UIUtility.CalculateSizePercentage(5, SettingsButtonFrame)
    }
}

local RegularMainFrameSize = MainFrame.Size
local RegularColorFrameSize = Colors:WaitForChild("Color").Size

local EmptyPixelColor = Color3.new(1, 1, 1)
local EmptyPixelTransparency = 0.35
local ColoredPixelTransparency = 0
local DefaultDrawingColor = Color3.new(0, 0, 0)
local DefaultStrokeThickness = 0
local SelectedStrokeThickness = 3.5

local SelectedColor = nil
local IsMouseHeld = false
local IsTouching = false
local IsErasing = false

local DefaultColumnCount = 9
local DefaultRowCount = 9
local DefaultBrushSize = 1
local DefaultDragToDrawState = true

local CurrentDrawing = nil
local CurrentCanvasGrid = nil -- The grid used to map a pixelframe to a location on the grid.
local Brush = nil
local CanvasPixelFrameIndex = 1

local IsMobileUser = false

local ActiveSettings = {
    ["DragToDraw"] =  DefaultDragToDrawState,
    ["GridSize"] = {
        ["RowCount"] = DefaultRowCount,
        ["ColumnCount"] = DefaultColumnCount   
    },
    ["BrushSize"] = DefaultBrushSize
}


local function GetPixelSize(RowCount, ColumnCount)
	local SizeX, SizeY
	
	if RowCount <= 0 or RowCount - 1 <= 0 then
		SizeY = PixelsFrame.AbsoluteSize.Y
	else
		SizeY = PixelsFrame.AbsoluteSize.Y / RowCount
	end
	
	if ColumnCount <= 0 or ColumnCount - 1 <= 0 then
		SizeX = PixelsFrame.AbsoluteSize.X
	else
		SizeX = PixelsFrame.AbsoluteSize.X / ColumnCount
	end
	
	return UDim2.fromOffset(SizeX, SizeY)
end

local DrawingController = {}

function DrawingController.Init()
    local DrawingSettingsController = require(script.Parent:WaitForChild("DrawingSettingsController")) -- Prevent recursive requires on drawing settings menu & drawing menu

    for _, FrameData in ipairs(TweenFrames) do
        local Frame = FrameData.Frame
        local Button = FrameData.Button
        local RegularFrameSize = FrameData.RegularFrameSize
        local EnlargedFrameSize = FrameData.EnlargedFrameSize
        Button.MouseEnter:Connect(function()
            UIUtility.Tween(Frame, 0.05, {Size = EnlargedFrameSize})
        end)
        Button.MouseLeave:Connect(function()
            UIUtility.Tween(Frame, 0.05, {Size = RegularFrameSize})
        end)
    end

    for _, ColorFrame in ipairs(Colors:GetChildren()) do
        if ColorFrame.Name == "Color" then
            local ColorButton = ColorFrame:WaitForChild("Button")
            local EnlargedFrameSize = UIUtility.CalculateSizePercentage(5, ColorFrame)
            local RegularFrameSize = ColorFrame.Size
            ColorButton.Activated:Connect(function()
                local Color = ColorFrame.BackgroundColor3
                IsErasing = false
                if SelectedColor ~= Color then
                    InterfaceSound.PlaySound("OpenUI")
                end
                DrawingController.SetActiveColor(Color)
            end)
            ColorButton.MouseEnter:Connect(function()
                UIUtility.Tween(ColorFrame, 0.05, {Size = EnlargedFrameSize})
            end)
            ColorButton.MouseLeave:Connect(function()
                UIUtility.Tween(ColorFrame, 0.05, {Size = RegularFrameSize})
            end)
        end
    end

    DrawingController.CreateCanvas(DefaultRowCount, DefaultColumnCount)
    DrawingController.SetActiveColor(DefaultDrawingColor)

    OnGridSizeChanged.Event:Connect(function(RowCount, ColumnCount)
        ActiveSettings.GridSize.RowCount = RowCount
        ActiveSettings.GridSize.ColumnCount = ColumnCount
        DrawingController.DestroyExistingCanvas()
        DrawingController.CreateCanvas(RowCount, ColumnCount)
    end)

    OnDragToDrawStateChanged.Event:Connect(function(DragState)
        ActiveSettings.DragToDraw = DragState
    end)

    OnBrushSizeChanged.Event:Connect(function(BrushSize)
        ActiveSettings.BrushSize = BrushSize
        Brush:SetSize(BrushSize)
    end)

    GetDrawingSetting.OnInvoke = function(SettingName)
        return ActiveSettings[SettingName]
    end

    RoleplayNameTextBox.Changed:Connect(function()
        local MaximumRoleplayNameLength = GameplayConstants.MaximumRoleplayNameLength
        RoleplayNameTextBox.Text = string.sub(RoleplayNameTextBox.Text, 1, MaximumRoleplayNameLength)
    end)

    EraserButton.Activated:Connect(DrawingController.SetErasingState, true)
    CloseButton.Activated:Connect(DrawingController.CloseMenu)

    SettingsButton.Activated:Connect(function()
        local IsMenuOpen = DrawingController.IsMenuOpen()
        if IsMenuOpen then
            DrawingController.CloseMenu(false, false)
        end
        DrawingSettingsController.OpenMenu()
    end)

    ShopButton.Activated:Connect(function()
        local IsMenuOpen = DrawingController.IsMenuOpen()
        if IsMenuOpen then
            DrawingController.CloseMenu(false)
        end
        ColorShopController.OpenMenu()
    end)

    MorphButton.Activated:Connect(function()
        local SerializedDrawing = Serialization.SerializeColorMap(CurrentDrawing)
        local Character = LocalPlayer.Character
        local RoleplayName = DrawingController.GetRoleplayName()
        DrawingController.CloseMenu()
        InterfaceSound.PlaySound("Morph")
        MorphRemote:InvokeServer(SerializedDrawing, RoleplayName)
        if Character then
            for _, Sound in ipairs(Character:GetDescendants()) do
                if Sound:IsA("Sound") then
                    Sound:Destroy()
                end
            end
        end
    end)
    
    ClearCanvasButton.Activated:Connect(function()
        local ClearConfirmFrameVisible = ClearConfirmFrame.Visible
        if ClearConfirmFrameVisible then
            DrawingController.HideClearConfirm()
        else
            DrawingController.ShowClearConfirm()
        end
    end)

    ClearConfirmButton.Activated:Connect(function()
        DrawingController.ClearCanvas()
        DrawingController.HideClearConfirm()
    end)

    DrawButton.Activated:Connect(function()
        local IsDrawingMenuOpen = DrawingController.IsMenuOpen()
        local IsDrawingSettingsMenuOpen = DrawingSettingsController.IsMenuOpen()
        if not IsDrawingSettingsMenuOpen then
            if IsDrawingMenuOpen then
                DrawingController.CloseMenu()
            else
                DrawingController.OpenMenu()
            end
        end
    end)

    SaveButton.Activated:Connect(function()
        local SaveMenuController = require(script.Parent:WaitForChild("SaveMenuController"))
        DrawingController.CloseMenu(false, false)
        SaveMenuController.OpenMenu()
    end)

    RunService.Stepped:Connect(function()
        local DragToDrawEnabled = ActiveSettings["DragToDraw"]
        if IsMouseHeld or IsTouching then
            if DragToDrawEnabled then
                DrawingController.SetHoveringPixel()
            end
        end

        local PixelSize = GetPixelSize(ActiveSettings.GridSize.RowCount, ActiveSettings.GridSize.ColumnCount)
        PixelUIGridLayout.CellSize = PixelSize
    end)
    
    UserInputService.InputBegan:Connect(function(Input)
        if Input.UserInputType == Enum.UserInputType.MouseButton1 then
            local DragToDrawEnabled = ActiveSettings["DragToDraw"]
            if not DragToDrawEnabled then 
                DrawingController.SetHoveringPixel()
            end
            IsMobileUser = false
            DrawingController.SetMouseHeldState(true)
        end
    end)
    
    UserInputService.InputEnded:Connect(function(Input)
        if Input.UserInputType == Enum.UserInputType.MouseButton1 then
            DrawingController.SetMouseHeldState(false)
        end
    end)

    UserInputService.TouchStarted:Connect(function()
        IsMobileUser = true
        DrawingController.SetTouchingState(true)
    end)

    UserInputService.TouchEnded:Connect(function()
        DrawingController.SetTouchingState(false)
    end)
end

function DrawingController.SetHoveringPixel()
    local IsMenuOpen = DrawingController.IsMenuOpen()
    local CanvasMetadata = CurrentCanvasGrid.Metadata
    local RowCount, ColumnCount = CanvasMetadata.RowCount, CanvasMetadata.ColumnCount
    
    if IsMenuOpen and CurrentDrawing and CurrentCanvasGrid then
        for Row = 1, RowCount do
            for Column = 1, ColumnCount do
                local PixelFrame = CurrentCanvasGrid:GetCellValue(Row, Column, CanvasPixelFrameIndex)
                local IsHoveringOverObject = UIUtility.IsHoveringOverObject(PixelFrame)
                if IsHoveringOverObject then
                    local SpannedPixels = Brush:GetSpannedPixels(Row, Column)
                    if IsErasing then
                        local IsPixelColored = CurrentDrawing:GetPixelColor(Row, Column)
                        if IsPixelColored then
                            InterfaceSound.PlaySound("Erase")
                        end
                        for _, SpannedPixelData in ipairs(SpannedPixels) do
                            local SPRow = SpannedPixelData.Row
                            local SPColumn = SpannedPixelData.Column
                            local SPPixelFrame = SpannedPixelData.PixelFrame
                            local IsSpannedPixelColored = CurrentDrawing:GetPixelColor(SPRow, SPColumn)
                            if IsSpannedPixelColored then
                                SPPixelFrame.BackgroundColor3 = EmptyPixelColor
                                SPPixelFrame.BackgroundTransparency = EmptyPixelTransparency
                                CurrentDrawing:ErasePixel(SPRow, SPColumn)
                            end
                        end
                    else
                        if SelectedColor then
                            for _, SpannedPixelData in ipairs(SpannedPixels) do
                                local SPRow = SpannedPixelData.Row
                                local SPColumn = SpannedPixelData.Column
                                local SPPixelFrame = SpannedPixelData.PixelFrame
                                SPPixelFrame.BackgroundColor3 = SelectedColor
                                SPPixelFrame.BackgroundTransparency = ColoredPixelTransparency
                                CurrentDrawing:ColorPixel(SPRow, SPColumn, SelectedColor)
                            end
                        end
                    end
                end
            end
        end
    end
end

function DrawingController.CreateCanvas(RowCount, ColumnCount)
    local PixelSize = GetPixelSize(RowCount, ColumnCount)
    CurrentDrawing = Drawing.new(RowCount, ColumnCount)
    CurrentCanvasGrid = Grid.new(RowCount, ColumnCount)
    PixelUIGridLayout.FillDirectionMaxCells = ColumnCount
    PixelUIGridLayout.CellSize = PixelSize

    local BrushSize = ActiveSettings.BrushSize
    if Brush == nil then
        Brush = BrushObject.new(BrushSize, CurrentCanvasGrid)
    else
        Brush:SetCanvas(CurrentCanvasGrid)
        Brush:SetSize(BrushSize)
    end

	for Row = 1, RowCount do
		for Column = 1, ColumnCount do
			local PixelClone = PixelTemplate:Clone()
			PixelClone.Name = "p".. tostring(Row).. ".".. tostring(Column)
			PixelClone.Visible = true
			PixelClone.Parent = PixelsFrame
            CurrentCanvasGrid:SetCellValue(Row, Column, CanvasPixelFrameIndex, PixelClone)
		end
	end
end

function DrawingController.DestroyExistingCanvas()
    local CanvasMetadata = CurrentCanvasGrid.Metadata
    local RowCount, ColumnCount = CanvasMetadata.RowCount, CanvasMetadata.ColumnCount
    for Row = 1, RowCount do
        for Column = 1, ColumnCount do
            local PixelFrame = CurrentCanvasGrid:GetCellValue(Row, Column, CanvasPixelFrameIndex)
            PixelFrame:Destroy()
        end
    end
    CurrentCanvasGrid:Destroy()
end

function DrawingController.ClearCanvas()
    local CanvasMetadata = CurrentCanvasGrid.Metadata
    local RowCount, ColumnCount = CanvasMetadata.RowCount, CanvasMetadata.ColumnCount
    CurrentDrawing:Clear()
    for Row = 1, RowCount do
        for Column = 1, ColumnCount do
            local PixelFrame = CurrentCanvasGrid:GetCellValue(Row, Column, CanvasPixelFrameIndex)
            PixelFrame.BackgroundColor3 = EmptyPixelColor
            PixelFrame.BackgroundTransparency = EmptyPixelTransparency
        end
    end
end

function DrawingController.GetRoleplayName()
    return RoleplayNameTextBox.Text
end

function DrawingController.ResetButtonSizes()
    for _, FrameData in ipairs(TweenFrames) do
        local Frame = FrameData.Frame
        local RegularFrameSize = FrameData.RegularFrameSize
        Frame.Size = RegularFrameSize
    end
    for _, ColorFrame in ipairs(Colors:GetChildren()) do
        if ColorFrame.Name == "Color" then
            ColorFrame.Size = RegularColorFrameSize
        end
    end
end

function DrawingController.DisableLocalInputs()
    -- Used to disable camera/character movement for mobile users. 
    local Character = LocalPlayer.Character
    CurrentCamera.CameraType = Enum.CameraType.Scriptable
    if Character then
        local Humanoid = Character:FindFirstChildOfClass("Humanoid")
        if Humanoid then
            Humanoid.WalkSpeed = 0
            Humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, false)
        end
    end
end

function DrawingController.EnableLocalInputs()
    -- Used to enable camera/character movement for mobile users. 
    local Character = LocalPlayer.Character
    local DefaultWalkSpeed = 16
    CurrentCamera.CameraType = Enum.CameraType.Custom
    if Character then
        local Humanoid = Character:FindFirstChildOfClass("Humanoid")
        if Humanoid then
            Humanoid.WalkSpeed = DefaultWalkSpeed
            Humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, true)
        end
    end
end

function DrawingController.OpenMenu()
    task.spawn(UIUtility.CloseAllUI, "DrawingController")
    OnDrawingMenuOpened:FireServer()
    if IsMobileUser then
        DrawingController.DisableLocalInputs()
    end
    PixelsFrame.Visible = false
    InterfaceSound.PlaySound("OpenUI")
    MainFrame.Size = UDim2.fromScale(0 , 0)
    MainFrame.Visible = true
    UIUtility.Tween(MainFrame, 0.1, {Size = RegularMainFrameSize}, true)
    PixelsFrame.Visible = true
    pcall(function()
        StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)
    end)
end

function DrawingController.CloseMenu(FullClose, SetDefaultStates)
    if FullClose == nil then
        FullClose = true
    end
    if SetDefaultStates == nil then
        SetDefaultStates = true
    end

    task.spawn(function()
        if IsMobileUser then
            DrawingController.EnableLocalInputs()
        end
        PixelsFrame.Visible = false
        OnDrawingMenuClosed:FireServer()
        if FullClose then
            InterfaceSound.PlaySound("CloseUI")
            pcall(function()
                StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, true)
            end)
        end
        DrawingController.ResetButtonSizes()
        if SetDefaultStates then
            DrawingController.SetErasingState(false)
            DrawingController.SetActiveColor(DefaultDrawingColor)
        end
        DrawingController.HideClearConfirm()
    end)
    
    UIUtility.Tween(MainFrame, 0.1, {Size = UDim2.fromScale(0, 0)}, true)
    MainFrame.Visible = false
    PixelsFrame.Visible = true
end

function DrawingController.IsMenuOpen()
    return MainFrame.Visible
end

function DrawingController.ShowClearConfirm()
    local VisiblePosition = UDim2.fromScale(0.93, 0.78)
    local HiddenPosition = UDim2.fromScale(0.59, 0.78)
    ClearConfirmFrame.Position = HiddenPosition
    ClearConfirmFrame.Visible = true
    UIUtility.Tween(ClearConfirmFrame, 0.1, {Position = VisiblePosition})
end

function DrawingController.HideClearConfirm()
    local VisiblePosition = UDim2.fromScale(0.93, 0.78)
    local HiddenPosition = UDim2.fromScale(0.6, 0.78)
    UIUtility.Tween(ClearConfirmFrame, 0.1, {Position = HiddenPosition}, true)
    ClearConfirmFrame.Visible = false
end

function DrawingController.SetErasingState(Is_Erasing)
    if Is_Erasing then
        DrawingController.SetActiveColor(nil)        
    else
        DrawingController.SetActiveColor(DefaultDrawingColor)        
    end

    IsErasing = Is_Erasing
end

function DrawingController.SetMouseHeldState(Is_MouseHeld)
    IsMouseHeld = Is_MouseHeld
end

function DrawingController.SetTouchingState(Is_Touching)
    IsTouching = Is_Touching
end

function DrawingController.SetActiveColor(Color)
    if SelectedColor then
        for _, ColorFrame in ipairs(Colors:GetChildren()) do
            if ColorFrame.Name == "Color" then
                local FrameColor = ColorFrame.BackgroundColor3
                if SelectedColor == FrameColor then
                    local UIStroke = ColorFrame:WaitForChild("UIStroke")
                    UIStroke.Thickness = DefaultStrokeThickness
                end
            end
        end
    end

    for _, ColorFrame in ipairs(Colors:GetChildren()) do
        if ColorFrame.Name == "Color" then
            local FrameColor = ColorFrame.BackgroundColor3
            local UIStroke = ColorFrame:WaitForChild("UIStroke")
            if Color == FrameColor then
                UIStroke.Thickness = SelectedStrokeThickness
            elseif Color == nil then
                UIStroke.Thickness = DefaultStrokeThickness
            end
        end
    end

    SelectedColor = Color
end

return DrawingController