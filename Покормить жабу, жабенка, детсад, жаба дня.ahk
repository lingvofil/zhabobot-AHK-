#Requires AutoHotkey v2.0
; =======================================================================
; == АВТОМАТИЧЕСКИЙ ПЛАНИРОВЩИК С УДОБНЫМ ФОРМАТОМ ДАТ ==
; == Формат: Date: "DD.MM.YYYY", Time: "HH:MM" ==
; =======================================================================

; --- НАСТРОЙКИ СЕТКИ КООРДИНАТ ---
GRID_START_DATE := "29.12.2025"
GRID_END_DATE := "08.02.2026"

F1::
{
    RunScheduling()
}

RunScheduling()
{
    ; --- НАСТРОЙКИ ЗАДАЧ (НОВЫЙ ФОРМАТ) ---
    local tasks := [
        ; Покормить жабу
        {
            Text: "покормить жабу",
            Date: "28.01.2026",
            Time: "23:50",
            IntervalHours: 6,
            IntervalMinutes: 10,
            Iterations: 0
        },
        ; Жабенок и жаба дня
        {
            Text: ["отправить жабенка в детский сад", "отправить жабенка на махач", "забрать жабенка", "жаба дня"],
            Date: "29.01.2026",
            Time: ["09:00", "12:00", "16:00", "00:01"],
            IntervalHours: 24,
            IntervalMinutes: 0,
            Iterations: 0
        },
        ; Брак вознаграждение
        {
            Text: "брак вознаграждение",
            Date: "29.01.2026",
            Time: "00:05",
            IntervalHours: 120,
            IntervalMinutes: 0,
            Iterations: 0
        },
        ; Клан вознаграждение
        {
            Text: "клан вознаграждение",
            Date: "16.01.2026",
            Time: "00:05",
            IntervalHours: 168,
            IntervalMinutes: 0,
            Iterations: 0
        },
        ; На арену
        {
            Text: "на арену",
            Date: "27.01.2026",
            Time: "8:18",
            IntervalHours: 1,
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
        if (task.Iterations = 0)
            continue
        local isMultiTask := (Type(task.Text) = "Array")
        totalTasks += isMultiTask ? task.Text.Length : 1
    }
    
    local completedTasks := 0
    local totalEvents := 0

    for task in tasks
    {
        if (task.Iterations = 0)
            continue
        
        ; Проверяем, массив ли это задач
        local isMultiTask := (Type(task.Text) = "Array")
        local taskCount := isMultiTask ? task.Text.Length : 1;
        
        if (isMultiTask)
        {
            ; Обрабатываем каждую подзадачу из массива
            Loop taskCount
            {
                completedTasks++
                local currentText := task.Text[A_Index]
                local currentTime := task.Time[A_Index]
                
                ToolTip("Выполняется задача " . completedTasks . " из " . totalTasks . ": " . currentText, 100, 100)
                
                local currentDateTime := ConvertToInternalFormat(task.Date, currentTime)
                
                Loop task.Iterations
                {
                    totalEvents++
                    local currentYear   := SubStr(currentDateTime, 1, 4)
                    local currentMonth  := SubStr(currentDateTime, 5, 2)
                    local currentDay    := SubStr(currentDateTime, 7, 2)
                    local currentHour   := SubStr(currentDateTime, 9, 2)
                    local currentMinute := SubStr(currentDateTime, 11, 2)

                    SendInput(currentText)
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

                    currentDateTime := DateAdd(currentDateTime, task.IntervalHours, "Hours")
                    currentDateTime := DateAdd(currentDateTime, task.IntervalMinutes, "Minutes")
                }
            }
        }
        else
        {
            ; Обычная одиночная задача
            completedTasks++
            ToolTip("Выполняется задача " . completedTasks . " из " . totalTasks . ": " . task.Text, 100, 100)
            
            local currentDateTime := ConvertToInternalFormat(task.Date, task.Time)
            
            Loop task.Iterations
            {
                totalEvents++
                local currentYear   := SubStr(currentDateTime, 1, 4)
                local currentMonth  := SubStr(currentDateTime, 5, 2)
                local currentDay    := SubStr(currentDateTime, 7, 2)
                local currentHour   := SubStr(currentDateTime, 9, 2)
                local currentMinute := SubStr(currentDateTime, 11, 2)

                SendInput(task.Text)
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

                currentDateTime := DateAdd(currentDateTime, task.IntervalHours, "Hours")
                currentDateTime := DateAdd(currentDateTime, task.IntervalMinutes, "Minutes")
            }
        }
    }
    
    ToolTip()
    MsgBox("Готово! Запланировано событий: " . totalEvents)
}

; --- ФУНКЦИЯ КОНВЕРТАЦИИ ДАТЫ ---
; Преобразует "DD.MM.YYYY" + "HH:MM" в "YYYYMMDDHHmmss"
ConvertToInternalFormat(dateStr, timeStr)
{
    ; Парсим дату (DD.MM.YYYY)
    local parts := StrSplit(dateStr, ".")
    local day := parts[1]
    local month := parts[2]
    local year := parts[3]
    
    ; Парсим время (HH:MM)
    local timeParts := StrSplit(timeStr, ":")
    local hour := timeParts[1]
    local minute := timeParts[2]
    
    ; Формируем строку YYYYMMDDHHmmss
    return year . Format("{:02}", month) . Format("{:02}", day) . Format("{:02}", hour) . Format("{:02}", minute) . "00"
}

; --- ФУНКЦИЯ АВТОГЕНЕРАЦИИ КООРДИНАТ ---
GenerateDateCoords(startDateStr, endDateStr)
{
    local coords := Map()
    
    ; Начальные координаты и шаги
    local startX := 1295
    local startY := 455
    local stepX := 48
    local stepY := 40
    
    ; Конвертируем даты из DD.MM.YYYY в YYYYMMDD
    local startParts := StrSplit(startDateStr, ".")
    local startInternalDate := startParts[3] . Format("{:02}", startParts[2]) . Format("{:02}", startParts[1]) . "000000"
    
    local endParts := StrSplit(endDateStr, ".")
    local endInternalDate := endParts[3] . Format("{:02}", endParts[2]) . Format("{:02}", endParts[1]) . "235959"
    
    local currentDate := startInternalDate
    
    local row := 0
    local col := 0
    
    ; Генерируем все даты от начальной до конечной
    while (currentDate <= endInternalDate)
    {
        local day := Integer(SubStr(currentDate, 7, 2))
        local month := Integer(SubStr(currentDate, 5, 2))
        local key := day . "-" . month;
        
        local x := startX + (col * stepX)
        local y := startY + (row * stepY)
        
        coords[key] := [x, y]
        
        col++
        if (col = 7)
        {
            col := 0;
            row++
        }
        
        ; Переходим к следующему дню
        currentDate := DateAdd(currentDate, 1, "Days")
    }
    
    return coords
}

Esc::
{
    ToolTip()
    ExitApp()
}