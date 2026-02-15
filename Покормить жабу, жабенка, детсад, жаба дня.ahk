#Requires AutoHotkey v2.0

; --- НАСТРОЙКИ СЕТКИ КООРДИНАТ ---
GRID_START_DATE := "26.01.2026"
GRID_END_DATE := "08.03.2026"

F1::
{
    RunScheduling()
}

RunScheduling()
{
    ; --- НАСТРОЙКИ ЗАДАЧ ---
    local tasks := [
        ; Жаба, жабенок, арена
        {
            Text: ["жаба дня", "откормить жабу", "покормить жабу", "отправить жабенка в детский сад", "на арену", "отправить жабенка на махач", "покормить жабу", "забрать жабенка", "покормить жабу"],
            Date: "23.02.2026",  ; Общая дата начала для всех
            Time: ["00:01", "01:00", "07:30", "09:00", "09:23", "12:00", "14:00", "16:00", "20:30"],  ; Время для каждой подзадачи
            DailyRepeats: [1, 1, 1, 1, 14, 1, 1, 1, 1],  ; Количество повторений в день
            IntervalHours: [24, 24, 24, 24, 1, 24, 24, 24, 24],  ; Интервал для каждой подзадачи
            IntervalMinutes: [0, 0, 0, 0, 0, 0, 0, 0, 0],
            Days: 4  ; Количество дней выполнения для всех подзадач
        },
        ; Брак вознаграждение
        {
            Text: "брак вознаграждение",
            Date: "08.02.2026",
            Time: "00:05",
            IntervalHours: 120,
            IntervalMinutes: 0,
            Iterations: 0
        },
        ; Клан вознаграждение
        {
            Text: "клан вознаграждение",
            Date: "06.02.2026",
            Time: "00:05",
            IntervalHours: 168,
            IntervalMinutes: 0,
            Iterations: 0
        }
    ]
    
    ; --- ГЕНЕРАЦИЯ КООРДИНАТ ---
    local dateCoords := GenerateDateCoords(GRID_START_DATE, GRID_END_DATE)

    ; --- ПОДГОТОВКА ---
    CoordMode("Mouse", "Screen")
    Click(1540, 1017)
    Sleep(500)

    ; --- ОСНОВНОЙ ЦИКЛ ---
    local totalTasks := 0
    for task in tasks
    {
        ; Пропускаем задачи с Iterations = 0
        if (task.HasOwnProp("Iterations") && task.Iterations = 0)
            continue
        ; Пропускаем задачи с Days = 0
        if (task.HasOwnProp("Days") && task.Days = 0)
            continue
            
        local isMultiTask := (Type(task.Text) = "Array")
        totalTasks += isMultiTask ? task.Text.Length : 1
    }
    
    local completedTasks := 0
    local totalEvents := 0

    for task in tasks
    {
        ; Пропускаем задачи с Iterations = 0
        if (task.HasOwnProp("Iterations") && task.Iterations = 0)
            continue
        ; Пропускаем задачи с Days = 0
        if (task.HasOwnProp("Days") && task.Days = 0)
            continue
        
        ; Определяем тип задачи
        local hasDays := task.HasOwnProp("Days")
        local hasDailyRepeats := task.HasOwnProp("DailyRepeats")
        local isMultiTask := (Type(task.Text) = "Array")
        
        if (hasDays && hasDailyRepeats && isMultiTask)
        {
            ; Тип: Объединенная задача с разными параметрами для каждой подзадачи
            Loop task.Text.Length
            {
                completedTasks++
                local currentText := task.Text[A_Index]
                local currentTime := task.Time[A_Index]
                local currentDailyRepeats := task.DailyRepeats[A_Index]
                local currentIntervalHours := task.IntervalHours[A_Index]
                local currentIntervalMinutes := task.IntervalMinutes[A_Index]
                
                ToolTip("Выполняется задача " . completedTasks . " из " . totalTasks . ": " . currentText, 100, 100)
                
                local numberOfDays := task.Days
                
                Loop numberOfDays
                {
                    local dayNumber := A_Index
                    local currentDayDate := ConvertToInternalFormat(task.Date, currentTime)
                    currentDayDate := DateAdd(currentDayDate, (dayNumber - 1), "Days")
                    
                    Loop currentDailyRepeats
                    {
                        totalEvents++
                        ProcessSingleEvent(currentText, currentDayDate, dateCoords)
                        currentDayDate := DateAdd(currentDayDate, currentIntervalHours, "Hours")
                        currentDayDate := DateAdd(currentDayDate, currentIntervalMinutes, "Minutes")
                    }
                }
            }
        }
        else if (task.HasOwnProp("Iterations"))
        {
            ; Тип: Обычная задача с итерациями
            completedTasks++
            ToolTip("Выполняется задача " . completedTasks . " из " . totalTasks . ": " . task.Text, 100, 100)
            
            local actualIterations := task.Iterations
            if (task.HasOwnProp("IterationsMultiplier"))
            {
                actualIterations := task.Iterations * task.IterationsMultiplier
            }
            
            local currentDateTime := ConvertToInternalFormat(task.Date, task.Time)
            
            Loop actualIterations
            {
                totalEvents++
                ProcessSingleEvent(task.Text, currentDateTime, dateCoords)
                currentDateTime := DateAdd(currentDateTime, task.IntervalHours, "Hours")
                currentDateTime := DateAdd(currentDateTime, task.IntervalMinutes, "Minutes")
            }
        }
    }
    
    ToolTip()
    MsgBox("Готово! Запланировано событий: " . totalEvents)
}

; --- ФУНКЦИЯ ОБРАБОТКИ ОДНОГО СОБЫТИЯ ---
ProcessSingleEvent(taskText, dateTime, dateCoords)
{
    local currentYear   := SubStr(dateTime, 1, 4)
    local currentMonth  := SubStr(dateTime, 5, 2)
    local currentDay    := SubStr(dateTime, 7, 2)
    local currentHour   := SubStr(dateTime, 9, 2)
    local currentMinute := SubStr(dateTime, 11, 2)

    SendInput(taskText)
    Sleep(250)
    Send("{Enter}")
    Sleep(750)
    Send("{Backspace 2}")
    Sleep(250)
    SendInput(Format("{:02}", currentMinute))
    Sleep(250)
    Send("+{Tab}")
    Sleep(250)
    SendInput(Format("{:02}", currentHour))
    Sleep(250)
    Send("+{Tab}")
    Sleep(500)

    local dateKey := Integer(currentDay) . "-" . Integer(currentMonth)
    if (dateCoords.Has(dateKey))
    {
        Click(dateCoords[dateKey][1], dateCoords[dateKey][2])
    }
    else
    {
        ToolTip()
        MsgBox("ОШИБКА: Координаты для даты " . dateKey . " не найдены.")
        ExitApp()
    }
    Sleep(500)
    Send("{Enter}")
    Sleep(1000)
}

; --- ФУНКЦИЯ КОНВЕРТАЦИИ ДАТЫ ---
ConvertToInternalFormat(dateStr, timeStr)
{
    local parts := StrSplit(dateStr, ".")
    local day := parts[1]
    local month := parts[2]
    local year := parts[3]
    
    local timeParts := StrSplit(timeStr, ":")
    local hour := timeParts[1]
    local minute := timeParts[2]
    
    return year . Format("{:02}", month) . Format("{:02}", day) . Format("{:02}", hour) . Format("{:02}", minute) . "00"
}

; --- ФУНКЦИЯ АВТОГЕНЕРАЦИИ КООРДИНАТ ---
GenerateDateCoords(startDateStr, endDateStr)
{
    local coords := Map()
    
    local startX := 1295
    local startY := 455
    local stepX := 48
    local stepY := 40
    
    local startParts := StrSplit(startDateStr, ".")
    local startInternalDate := startParts[3] . Format("{:02}", startParts[2]) . Format("{:02}", startParts[1]) . "000000"
    
    local endParts := StrSplit(endDateStr, ".")
    local endInternalDate := endParts[3] . Format("{:02}", endParts[2]) . Format("{:02}", endParts[1]) . "235959"
    
    local currentDate := startInternalDate
    
    local row := 0
    local col := 0
    
    while (currentDate <= endInternalDate)
    {
        local day := Integer(SubStr(currentDate, 7, 2))
        local month := Integer(SubStr(currentDate, 5, 2))
        local key := day . "-" . month
        
        local x := startX + (col * stepX)
        local y := startY + (row * stepY)
        
        coords[key] := [x, y]
        
        col++
        if (col = 7)
        {
            col := 0
            row++
        }
        
        currentDate := DateAdd(currentDate, 1, "Days")
    }
    
    return coords
}

Esc::
{
    ToolTip()
    ExitApp()
}
