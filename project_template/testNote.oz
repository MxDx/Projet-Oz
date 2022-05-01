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

    % fun {DurationTrans DurationTuple}
    %     ExtendedPartition = {PartitionToTimedList Duration.1}
    %     local fun {Helper Duration Partition}
    %         case Partition
    %         of H|T then
    %             case H
    %             of HPart|TPart then
    %                 if TPart == nil then
    %                     note(name:HPart.name
    %                         octave:HPart.octave
    %                         sharp:HPart.sharp
    %                         duration:Duration
    %                         instrument:HPart.instrument)
    %                 else
    %                     note(name:HPart.name
    %                         octave:HPart.octave
    %                         sharp:HPart.sharp
    %                         duration:HPart.Duration
    %                         instrument:HPart.instrument)|{Helper Duration TPart}
    %                 end
    %             else
    %                 "DurationTrans: Error"
    %             end
    %         end
    %     in
    %         {Helper DurationTuple.seconds ExtendedPartition}
    %     end
    % end

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

    fun {Transpose NoteTuple Amount} 
        local Index SharpTones OrderOfTones
            fun {HelperFind Note OrderOfTones Acc}
                case OrderOfTones
                of H|T then
                    if Note == H then Acc
                    elseif {Member H SharpTones} then
                        {HelperFind Note T (Acc+2)}
                    else
                        {HelperFind Note T (Acc+1)}
                    end
                else
                    ~6
                end
            end
            fun {HelperTranspose Index NoteTuple Amount Acc}
                if Acc == Amount then NoteTuple
                elseif {Member NoteTuple.name SharpTones} then
                    if NoteTuple.sharp then
                        {HelperTranspose Index+1 note(name:NoteTuple.name
                                                octave:NoteTuple.octave
                                                sharp:false
                                                duration:NoteTuple.duration
                                                instrument:NoteTuple.instrument) Amount (Acc+1)}
                    else
                        {HelperTranspose Index+1 note(name:{Nth OrderOfTones Index+1}
                                                octave:NoteTuple.octave
                                                sharp:true
                                                duration:NoteTuple.duration
                                                instrument:NoteTuple.instrument) Amount (Acc+1)}
                    end
                else
                    if NoteTuple.name == b then
                        {HelperTranspose 0 note(name:c
                                                octave:NoteTuple.octave
                                                sharp:false
                                                duration:NoteTuple.duration
                                                instrument:NoteTuple.instrument) Amount (Acc+1)}
                    else
                        {HelperTranspose Index+1 note(name:{Nth OrderOfTones Index+1}
                                                octave:NoteTuple.octave
                                                sharp:false
                                                duration:NoteTuple.duration
                                                instrument:NoteTuple.instrument) Amount (Acc+1)}
                    end
                end
            end
        in 
            OrderOfTones = c|d|e|f|g|a|b|nil 
            SharpTones = c|d|f|g|a|b|nil
            {HelperTranspose {HelperFind Note.name OrderOfTones 0} NoteTuple Amount 0}
        end
    end

    % fun {TransposeTrans TransposeTuple}
    %     local ExtendedPartition
    %         fun {Helper Partition Down Amount}
    %             case Partition
    %             of nil then nil
    %             [] H|T then  
    %                 if Down then
    %                     local
    %                         fun {HelperDown H Amount Acc}
    %                             if Amount == Acc then
    %                                 H
    %                             else
    %                                 if 
    %                             end
    %             else
    %                 6
    %             end               
    %         end
    %     in
    %         ExtendedPartition = {PartitionToTimedList TransposeTuple.1|nil}
    %         if TransposeTuple.semitones < 0 then
    %             {Helper ExtendedPartition true ~TransposeTuple.semitones}
    %         else
    %             {Helper ExtendedPartition false TransposeTuple.semitones}
    %         end
    %         {Helper ExtendedPartition }
    %     end
    % end

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

    {Browse 0}
    ListOfNotes = (c4|b#6|nil)
    % {Browse ListOfNotes}
    List = {ChordToExtended ListOfNotes}
    % {Browse List}
    PartitionChord = c4|b#4|ListOfNotes|a|nil

    % {Browse {Nth PartitionChord 3}}
    % {Browse {Transpose {NoteToExtended a4} 4}}
   
    %% Test Duration
    DurationTuple = duration(1:PartitionChord seconds:6.0)
    PartitionToTest = DurationTuple|nil
    DurationTuple2 = duration(1:PartitionToTest seconds:2.0)
    {Browse {PartitionToTimedList PartitionToTest}}
    % {Browse {PartitionToTimedList DurationTuple2|nil}}

    %% Test Stretch
    TupleStretch = stretch(factor:2.0 1:PartitionChord)|nil
    TupleDuration = stretch(factor:1.0 1:PartitionToTest)
    %{Browse TupleStretch}
    %{Browse {PartitionToTimedList TupleStretch}}
    %{Browse {PartitionToTimedList TupleDuration|nil}}

    %% Test Drone
    DroneList = drone(note:a6|b#2|nil amount:4)|c5|nil
    {Browse {PartitionToTimedList DroneList}}
end



