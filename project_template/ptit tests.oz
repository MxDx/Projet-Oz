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

    NoteValue
    InttoNote
    NotestoInt
    fun {TransposeTrans TransposeTuple}
        %Notes = c|c#|d|d#|e|f|f#|g|g#|a|a#|b
        %Correspond aux nombres 1|2|3|4|5|...|12
        NotestoInt = nti(c:1 d:3 e:5 f:6 g:8 a:10 b:12)
        InttoNote = itn(1:c#false 2:c#true 3:d#false 4:d#true 5:e#false 6:f#false 7:f#true 8:g#false 9:g#true 10:a#false 11:a#true 12:b#false)
        local
            ExtendedPartition
            TransposedNote
            Octave
            NewName
            fun {Helper Semitone Partition}
                NoteValue = 0
                case Partition
                of nil then 
                    nil
                [] H|T then
                    {Browse 2}
                    case H
                    of _|_ then
                        {Helper Semitone H}|{Helper Semitone T}
                    else
                        {Browse 3}
                        {Browse H.name}
                        {Browse H.sharp}
                        if H.sharp then
                            NoteValue = NotestoInt.(H.name) + 1
                        else
                            NoteValue = NotestoInt.(H.name)
                        end
                        {Browse 4}
                        TransposedNote = NoteValue + Semitone
                        Octave = {ComputeOctave TransposedNote H.octave NewName}
                        note(duration:H.duration 
                            instrument:H.instrument 
                            name:((InttoNote.NewName).1) 
                            octave:Octave 
                            sharp:((InttoNote.NewName).2))|{Helper Semitone T}
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
            else
                {NoteToExtended H}|{PartitionToTimedList T}
            end
        else
            1
        end
    end
    DurationTuple
    TimedList

in
    % Note = {NoteToExtended c}
    % {Browse Note}
    % % SilenceTest = {NoteToExtended silence}
    % % {Browse SilenceTest}
    % TestChords = a1|a2|a3|a4|nil

    % {Browse TestChords}
    % Chord = {ChordToExtended TestChords}
    % {Browse Chord}

    ListOfNotes = (c4|d6|nil)
    % {Browse ListOfNotes}
    % List = {ChordToExtended ListOfNotes}
    % {Browse List}
    PartitionChord = c4|d4|ListOfNotes|a|nil


    {Browse {PartitionToTimedList PartitionChord}}

    % {Browse {Nth PartitionChord 3}}
    {Browse 1}
    {Browse {TransposeTrans tupl(semitones:4 1:PartitionChord)}}
   
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