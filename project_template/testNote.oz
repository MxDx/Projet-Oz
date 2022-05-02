declare
local
    fun {NoteToExtended Note}
        case Note
        of Name#Octave then
           note(name:Name octave:Octave sharp:true duration:1.0 instrument:none)
        [] Atom then
           case {AtomToString Atom}
           of [_] then
              note(name:Atom octave:4 sharp:false duration:1.0 instrument:none)
           [] [N O] then
              note(name:{StringToAtom [N]}
                   octave:{StringToInt [O]}
                   sharp:false
                   duration:1.0
                   instrument: none)
           end
        end 
    end
    
    Note
    SilenceTest
    TestChords

    fun {ChordToExtended Chord}
        case Chord
        of nil then
            nil
        [] H|T then
            {NoteToExtended H}|{ChordToExtended T}
        else
            2
        end
    end



    fun {AddTogether List Tail}
        case List
        of nil then
            {PartitionToTimedList Tail} 
        [] H|T then 
            H|{AddTogether T Tail}
        end
    end

    fun {DurationTrans DurationTuple}
        local ExtendedPartition 
            fun {Helper Partition Duration}
                case Partition
                of nil then nil
                [] H|T then
                    case H 
                    of _|_ then
                        {Helper H Duration}|{Helper T Duration}
                    [] silence(duration:_) then
                        silence(duration:Duration.seconds)|{Helper T Duration}
                    else 
                        note(name:H.name
                            octave:H.octave
                            sharp:H.sharp
                            duration:Duration.seconds
                            instrument:H.instrument)|{Helper T Duration}
                    end
                else
                    errorDurationTrans
                end
            end
        in
            ExtendedPartition = {PartitionToTimedList DurationTuple.1}
            {Helper ExtendedPartition DurationTuple}
        end
    end
    
    fun {StretchTrans StretchTuple}
        local ExtendedPartition 
            fun {Helper Stretch Partition}
                case Partition
                of nil then nil
                [] H|T then
                    case H
                    of _|_ then
                        {Helper Stretch H}|{Helper Stretch T}
                    [] silence(duration:D) then
                        silence(duration:(D*Stretch.factor))|{Helper Stretch T}
                    else
                        note(name:H.name
                            octave:H.octave
                            sharp:H.sharp
                            duration:(H.duration * Stretch.factor)
                            instrument:H.instrument)|{Helper Stretch T}
                    end
                else
                    stretchTransError
                end
            end
        in
            ExtendedPartition = {PartitionToTimedList StretchTuple.1}
            {Helper StretchTuple ExtendedPartition}
        end
    end

    fun {DroneTrans DroneTuple}
        local ExtendedPartition
            fun {Helper Partition Amount Acc}
                case Partition
                of H|T then  
                    if Amount == Acc then
                        H|nil 
                    else
                        H|{Helper Partition Amount (Acc+1)}
                    end
                else
                    droneTransError
                end               
            end
        in  
            if DroneTuple.amount < 1 then
                droneTransLessThan1Error
            else
            ExtendedPartition = {PartitionToTimedList DroneTuple.note|nil}
            {Helper ExtendedPartition DroneTuple.amount 1}
            end
        end
    end

 
    fun {ComputeOctave TransValue Octave IntNoteName}
        local
            fun {Helper TransValue Octave}
                if TransValue > 12 then
                    {Helper TransValue-12 Octave+1}
                elseif TransValue < 1 then
                    {Helper TransValue+12 Octave-1}
                else
                    IntNoteName = TransValue
                    Octave
                end
            end     
        in
            {Helper TransValue Octave}
        end
    end

    InttoNote
    NotestoInt
    fun {TransposeTrans TransposeTuple}
        NotestoInt = nti(c:1 d:3 e:5 f:6 g:8 a:10 b:12) %We add one in the code if note is sharp
        InttoNote = itn(1:c#false 2:c#true 3:d#false 4:d#true 5:e#false 6:f#false 7:f#true 8:g#false 9:g#true 10:a#false 11:a#true 12:b#false)
        local
            ExtendedPartition
            fun {Helper Semitone Partition}
                case Partition
                of nil then 
                    nil
                [] H|T then
                    case H
                    of _|_ then
                        {Helper Semitone H}|{Helper Semitone T}
                    [] silence(duration:_) then
                        H|{Helper Semitone T}
                    else
                        local
                            NoteValue
                            TransposedNote
                            Octave
                            NewName
                        in
                            if H.sharp then
                                NoteValue = NotestoInt.(H.name) + 1
                            else
                                NoteValue = NotestoInt.(H.name)
                            end
                            TransposedNote = NoteValue + Semitone
                            Octave = {ComputeOctave TransposedNote H.octave NewName}
                            note(duration:H.duration 
                                instrument:H.instrument 
                                name:((InttoNote.NewName).1) 
                                octave:Octave 
                                sharp:((InttoNote.NewName).2))|{Helper Semitone T}
                        end
                    end
                else
                    transposeTransError
                end
            end
        in
            ExtendedPartition = {PartitionToTimedList TransposeTuple.1}
            {Browse ExtendedPartition}
            {Helper TransposeTuple.semitones ExtendedPartition}
        end
    end


    % Fonction qui convertis une partition en liste de notes étendues
    fun {PartitionToTimedList Partition}
        case Partition 
        of nil then
            nil
        [] H|T then
            case H 
            of _|_ then
                {PartitionToTimedList H}|{PartitionToTimedList T}
            [] note(duration:D instrument:I name:N octave:O sharp:S) then
                H|{PartitionToTimedList T}
            [] stretch(factor:F 1:P) then
                {AddTogether {StretchTrans H} T}
            [] duration(1:P seconds:D) then
                {AddTogether {DurationTrans H} T}
            [] drone(note:N amount:A) then
                {AddTogether {DroneTrans H} T}
            [] transpose(semitones:S 1:P) then
                {AddTogether {TransposeTrans H} T}
            [] silence(duration:_) then
                H|{PartitionToTimedList T}
            [] silence then
                silence(duration:1.0)|{PartitionToTimedList T}
            else
                {NoteToExtended H}|{PartitionToTimedList T}
            end
        else
            1
        end
    end

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    fun {MixCalcul Note Div}
        local NotestoInt H F
            fun {Helper Amount Acc Div}
                if Amount == Acc then
                    nil
                else
                    (0.5 * {Float.sin ((2.0*3.14159265359*{IntToFloat Acc}*F)/44100.0)})/Div|{Helper Amount Acc+1 Div}
                end
            end
        in
            NotestoInt = nti(c:1 d:3 e:5 f:6 g:8 a:10 b:12)
            if Note.sharp then
                H = 12*(Note.octave - 4) + NotestoInt.(Note.name) + 1 - 10
            else
                H = 12*(Note.octave - 4) + NotestoInt.(Note.name) - 10
            end
            F = {Pow 2.0 {IntToFloat H}/12.0} * 440.0
            {Helper {FloatToInt Note.duration*44100.0} 0 Div}
        end
    end

    fun {AddZeros NbZeros List}
        case List
        of nil then
            if NbZeros > 0 then
                0.0|{AddZeros NbZeros-1 nil}
            else
                nil
            end
        [] H|T then
            H|{AddZeros NbZeros T}
        end
    end

    fun {Merge P2T MergeList}
        local
            fun {Helper MergeList OldMerge}
                case MergeList
                of nil then
                    OldMerge
                [] H|T then
                    local
                        ListToMerge = {Mix P2T H.2}
                        CompletedListToMerge
                        ListToMergeLength = {Length ListToMerge}
                        OldMergeLength = {Length OldMerge}
                    in
                        if ListToMergeLength > OldMergeLength then
                            CompletedListToMerge = {AddZeros (ListToMergeLength-OldMergeLength) OldMerge}
                            {Helper T {List.mapInd {Map ListToMerge fun {$ E} E*H.1 end} fun {$ I E} (E + {Nth CompletedListToMerge I}) end}}
                        elseif ListToMergeLength < OldMergeLength then 
                            CompletedListToMerge = {AddZeros (~ListToMergeLength+OldMergeLength) ListToMerge}
                            {Helper T {List.mapInd {Map CompletedListToMerge fun {$ E} E*H.1 end} fun {$ I E} (E + {Nth OldMerge I}) end}}
                        else
                            {Helper T {List.mapInd {Map ListToMerge fun {$ E} E*H.1 end} fun {$ I E} (E + {Nth OldMerge I}) end}}
                        end
                    end
                else
                    ~1
                end
            end
        in  
            {Helper MergeList.2 {Map {Mix P2T MergeList.1.2} fun {$ E} E*MergeList.1.1 end}}
            % MergeList.2
            % {Map {Mix P2T MergeList.1.2} fun {$ E} E*MergeList.1.1 end}
        end
    end

    fun {MixRepeat Music Amount}
        local
            fun {Helper Music Amount}
                if Amount == 0 then
                    nil
                else
                    Music|{Helper Music Amount-1}
                end
            end
        in
            {Flatten {Helper Music Amount}}
        end
    end

    fun {Loop M S}
        local
            fun {Helper M S Length}
                if (S-Length) < 0.0 then
                    local
                        fun {HelperLast M S}
                            if S =< 0.0 then
                                nil
                            else
                                M.1|{HelperLast M.2 S-(1.0/44100.0)}
                            end
                        end
                    in 
                        {HelperLast M S}
                    end
                elseif (S-Length) == 0.0 then
                    M|nil
                else
                    M|{Helper M S-Length Length}
                end
            end
        in
            {Flatten {Helper M S {IntToFloat{Length M}}/44100.0}}
        end
    end

    fun {Clip Low High M}
        local
            fun {Helper I E} 
                if E =< {Nth Low I} then {Nth Low I}
                elseif E >= {Nth High I} then {Nth High I} 
                else E end 
            end
        in
            {List.mapInd M Helper}
        end
    end

    % fun {Echo M Delay}
    %     local
    %         fun {Helper M Amount Acc}
    %             if Acc == Delay then
    %                 M+{Nth Acc - Delay}
    %             else
    %                 M|{Helper M Amount-1}
    %             end
    %         end
    %     in
    %         {Flatten {Helper M Delay}}
    %     end
    % end

    fun {Mix P2T Music}
        local
            fun {Helper Partition}
                case Partition
                of nil then
                    nil
                [] H|T then
                    case H
                    of HChord|TChord then
                        local ChordAdd
                            fun {HelperChord Old Current Div}
                                case Current
                                of nil then Old
                                [] H2|T2 then
                                    {HelperChord {List.mapInd {MixCalcul H2 Div} fun {$ I E} (E + {Nth Old I}) end} T2 Div}
                                else
                                    ~3
                                end
                            end
                        in 
                            % {Map {HelperChord {MixCalcul HChord} TChord} fun {$ E} (E/{IntToFloat {Length H}}) end}
                            {HelperChord {MixCalcul HChord {IntToFloat {Length H}}} TChord {IntToFloat {Length H}}}
                        end
                    [] note(duration:_ instrument:_ name:_ octave:_ sharp:_) then
                        {MixCalcul H 1.0}|{Helper T}
                    else
                        ~2
                    end
                else
                    ~1
                end
            end
            fun {HelperMusic P2T Music}
                case Music
                of nil then nil
                [] H|T then
                    case H
                    of nil then nil
                    [] samples(1:S) then
                        S|{HelperMusic P2T T}
                    [] partition(1:P) then
                        {Helper {P2T P}}|{HelperMusic P2T T}
                    [] wave(1:Filename) then
                        {Project.readFile Filename}|{HelperMusic P2T T}
                    [] merge(1:MergeList) then
                        {Merge P2T MergeList}|{HelperMusic P2T T}
                    [] reverse(1:M) then
                        {Reverse {Flatten {HelperMusic P2T M}}}|{HelperMusic P2T T}
                    [] repeat(amount:A 1:M) then
                        {MixRepeat {Flatten {HelperMusic P2T M}} A}|{HelperMusic P2T T}
                    [] loop(seconds:S 1:M) then
                        {Loop {Flatten {HelperMusic P2T M}} S}|{HelperMusic P2T T}
                    [] clip(low:SLow high:SHigh 1:M) then
                        {Clip SLow SHigh {Flatten {HelperMusic P2T M}}}|{HelperMusic P2T T}
                    % [] echo(delay:D 1:M) then
                    %     {Echo {Flatten {HelperMusic P2T M}} D}|{HelperMusic P2T T}
                    else
                        ~5
                    end
                else
                    ~4
                end
            end
        in
            {Flatten {HelperMusic P2T Music}}
            % {Helper {P2T Music.1.1}}
        end
    end

    DurationTuple
    TimedList
    CWD
    Project
    Music
    Pilou
in
    % Note = {NoteToExtended c}
    % {Browse Note}
    % % SilenceTest = {NoteToExtended silence}
    % % {Browse SilenceTest}
    % TestChords = a1|a2|a3|a4|nil

    % {Browse TestChords}
    % Chord = {ChordToExtended TestChords}
    % {Browse Chord}
    CWD = 'project_template/' % Put here the **absolute** path to the project files
    [Project] = {Link [CWD#'Project2022.ozf']}
    Music = samples([1.0 0.0 0.5])|nil
    Music2 = samples([0.5 0.5])|nil
    {Browse 0}
    % {Browse {Project.run Mix PartitionToTimedList [merge([0.5#Music])] 'out.wav'}}
    % {Browse Music.1.1}
    % {Browse {Merge PartitionToTimedList [0.5#Music]}}
    {Browse {Merge PartitionToTimedList [1.0#Music]}}
    {Browse {Merge PartitionToTimedList [0.5#Music 0.5#Music2]}}
    % {Browse {Project.run Mix PartitionToTimedList [samples({Project.readFile CWD#'/wave/animals/cow.wav'})] 'out.wav'}}
    % {Browse {Project.run Mix PartitionToTimedList [loop(seconds:2.0 1:[samples({Project.readFile CWD#'/wave/animals/cat.wav'})])] 'outR.wav'}}
    % {Browse {Project.run Mix PartitionToTimedList [reverse([samples({Project.readFile CWD#'/wave/animals/cow.wav'})])] 'outR.wav'}}
    % {Browse {Project.run Mix PartitionToTimedList [repeat(amount:2 1:[samples({Project.readFile CWD#'/wave/animals/cow.wav'})])] 'outR.wav'}}
    % High = note(name:a
                % octave:5
                % sharp:false
                % duration:5.0
                % instrument: none)
    % Low = note(name:a
                % octave:3
                % sharp:false
                % duration:5.0
                % instrument: none)
% 
    % Mix_High = {Mix PartitionToTimedList [partition([High])]}
    % Mix_Low = {Mix PartitionToTimedList [partition([Low])]}
    % {Browse Mix_High}
    % {Browse Mix_Low}
    % {Browse {Clip [0 0 0 0 0 0 0] [2 2 2 2 2 2 2] [~3 ~2 ~1 0 1 2 3]}} 
    % {Browse {Project.run Mix PartitionToTimedList [clip(high:Mix_High low:Mix_Low 1:[samples({Project.readFile CWD#'/wave/animals/cow.wav'})])] 'outR.wav'}}
    % ListOfNotes = (c4|b#6|nil)
    % {Browse ListOfNotes}
    % List = {ChordToExtended ListOfNotes}
    % {Browse List}
    % PartitionChord = c4|b#4|ListOfNotes|a|nil

    % TestAddList = [1 2 3 4 5]
    % TestAddList2 = [1 1 1]

    % Test = 0.5#Music
    % {Browse Test.2}
    
    % {Browse {Clip 2 3 TestAddList}}

    % {Browse {List.mapInd TestAddList fun {$ I E} (E + {Nth TestAddList2 I}) end}}
    % Factor = 2.0
    % {Browse {Map [2.0 2.0 2.0] fun {$ E} (E/Factor) end}}
    % {Browse Music.1.1}
    % {Browse {PartitionToTimedList Music.1.1}}
    % {Browse {Mix PartitionToTimedList Music}}
    % {Browse {Length {Mix PartitionToTimedList [loop(seconds:2.0 1:[samples({Project.readFile CWD#'/wave/animals/cat.wav'})])]}}}
    % {Browse 1}

    % {Browse {MixCalcul {NoteToExtended a4} 1.0}}
    % {Browse {MixCalcul {NoteToExtended a5} 1.0}}
    % {Browse {Nth {MixCalcul {NoteToExtended c#5} 1.0} 11}}
    % {Browse {Length {MixCalcul {NoteToExtended a4} 1.0}}}
    % {Browse {Nth {MixCalcul {NoteToExtended a5} 1.0} 2}}
    % {Browse [{ChordToExtended [a4 b4]}]}
    % {Browse {Mix PartitionToTimedList [partition([{ChordToExtended [a4 a4]}])]}}
    % {Browse {Nth {Mix PartitionToTimedList [partition([a4])]} 22050}}

    % {Browse {PartitionToTimedList PartitionChord}}

    % {Browse {Nth PartitionChord 3}}
    % {Browse {TransposeTrans tupl(1:a4|nil semitones:4)}}
   
    %%%% Test Duration
    %DurationTuple = duration(1:PartitionChord seconds:6.0)
    %PartitionToTest = DurationTuple|nil
    %DurationTuple2 = duration(1:PartitionToTest seconds:2.0)
    %{Browse {PartitionToTimedList PartitionToTest}}
    %{Browse {PartitionToTimedList DurationTuple2|nil}}

    %%%% Test Stretch
    %TupleStretch = stretch(factor:2.0 1:PartitionChord)|nil
    %TupleDuration = stretch(factor:1.0 1:PartitionToTest)
    %{Browse TupleStretch}
    %{Browse {PartitionToTimedList TupleStretch}}
    %{Browse {PartitionToTimedList TupleDuration|nil}}

    %%%% Test Drone
    %DroneList = drone(note:a6|b#2|nil amount:4)|c5|nil
    %{Browse {PartitionToTimedList DroneList}}
end



