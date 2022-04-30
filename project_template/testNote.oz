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

    fun {DurationTrans DurationTuple}
        local ExtendedPartition 
            fun {Helper Duration Partition}
                case Partition
                of nil then nil
                [] H|T then 
                    case H
                    of HPart|TPart then
                        note(name:HPart.name
                            octave:HPart.octave
                            sharp:HPart.sharp
                            duration:Duration.seconds
                            instrument:HPart.instrument)|{Helper Duration TPart}
                    else
                        if T == nil then
                            note(name:H.name
                                octave:H.octave
                                sharp:H.sharp
                                duration:Duration.seconds
                                instrument:H.instrument)
                        else
                            note(name:H.name
                                octave:H.octave
                                sharp:H.sharp
                                duration:Duration.seconds
                                instrument:H.instrument)|{Helper Duration T}
                        end
                    end
                else
                    "DurationTrans: Error"
                end
            end
        in
            if {IsList DurationTuple.1} then
                ExtendedPartition = {PartitionToTimedList DurationTuple.1}
            else
                ExtendedPartition = {PartitionToTimedList DurationTuple.1|nil}
            end
            {Helper DurationTuple ExtendedPartition}
        end
    end
    
    fun {StretchTrans StretchTuple}
        local ExtendedPartition 
            fun {Helper Stretch Partition}
                case Partition
                of nil then nil
                [] H|T then 
                    case H
                    of HPart|TPart then
                        note(name:H.name
                            octave:H.octave
                            sharp:H.sharp
                            duration:H.duration*Stretch
                            instrument:H.instrument)|{Helper Stretch TPart}
                    else
                        if T == nil then
                            note(name:H.name
                                octave:H.octave
                                sharp:H.sharp
                                duration:H.duration * Stretch.factor
                                instrument:H.instrument)
                        else
                            note(name:H.name
                                octave:H.octave
                                sharp:H.sharp
                                duration:H.duration * Stretch.factor
                                instrument:H.instrument)|{Helper Stretch T}
                        end
                    end
                else
                    "StretchTrans: Error"
                end
            end
        in
            ExtendedPartition = {PartitionToTimedList StretchTuple.1|nil}
            if {IsList ExtendedPartition.1} then
                ExtendedPartition = {PartitionToTimedList StretchTuple.1}
            else
                ExtendedPartition = ExtendedPartition
            end
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
                end               
            end
        in
            ExtendedPartition = {PartitionToTimedList DroneTuple.note|nil}
            {Helper ExtendedPartition DroneTuple.amount 1}
        end
    end

    % Fonction qui convertis une partition en liste de notes étendues
    fun {PartitionToTimedList Partition}
        case Partition 
        of nil then
        nil
        [] H|T then
            case H 
            of ChordH|ChordT then
                case ChordH
                of note(duration:D instrument:I name:N octave:O sharp:S) then
                        H|{PartitionToTimedList T}
                else
                    {ChordToExtended H}|{PartitionToTimedList T}
                end
            [] note(duration:D instrument:I name:N octave:O sharp:S) then
                H|{PartitionToTimedList T}
            [] stretch(factor:F 1:P) then
                {StretchTrans H}|{PartitionToTimedList T}
            [] duration(1:P seconds:D) then
                {DurationTrans H}|{PartitionToTimedList T}
            [] drone(note:N amount:A) then
                {DroneTrans H}|{PartitionToTimedList T}
            else
                {NoteToExtended H}|{PartitionToTimedList T}
            end
        else
            "input invalide"
        end
    end

    DurationTuple

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
    ListOfNotes = c4|b#6|nil
    % {Browse ListOfNotes}
    List = {ChordToExtended ListOfNotes}
    % {Browse List}
    PartitionChord = c4|b#4|ListOfNotes|a|nil
   
    {Browse {PartitionToTimedList PartitionChord}}

    
    DurationTuple = duration(1:PartitionChord seconds:6.0)
    Tuple = stretch(factor:1.0 1:DurationTuple)
    % {Browse {PartitionToTimedList Tuple.1}}

    {Browse {PartitionToTimedList Tuple.1|nil}}
    % {Browse {StretchTrans Tuple}}
    % {Browse {PartitionToTimedList DurationTuple|nil}}
end



