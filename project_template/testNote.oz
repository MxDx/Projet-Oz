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
                of H|T then 
                    case H
                    of HPart|TPart then
                        if TPart == nil then
                            note(name:HPart.name
                                octave:HPart.octave
                                sharp:HPart.sharp
                                duration:Duration
                                instrument:HPart.instrument)
                        else
                            note(name:HPart.name
                                octave:HPart.octave
                                sharp:HPart.sharp
                                duration:HPart.Duration
                                instrument:HPart.instrument)|{Helper Duration TPart}
                        end
                    else
                        note(name:H.name
                            octave:H.octave
                            sharp:H.sharp
                            duration:Duration
                            instrument:H.instrument)
                    end
                else
                    "StretchTrans: Error"
                end
            end
        in
            ExtendedPartition = {PartitionToTimedList DurationTuple.1|nil}
            {Helper DurationTuple.duration ExtendedPartition}
        end
    end
    
    fun {StretchTrans ScretchTuple}
        local ExtendedPartition 
            fun {Helper Scretch Partition}
                case Partition
                of H|T then 
                    case H
                    of HPart|TPart then
                        if TPart == nil then
                            note(name:HPart.name
                                octave:HPart.octave
                                sharp:HPart.sharp
                                duration:HPart.duration * Scretch.factor
                                instrument:HPart.instrument)
                        else
                            note(name:HPart.name
                                octave:HPart.octave
                                sharp:HPart.sharp
                                duration:HPart.duration * Scretch.factor
                                instrument:HPart.instrument)|{Helper Scretch TPart}
                        end
                    else
                        note(name:H.name
                            octave:H.octave
                            sharp:H.sharp
                            duration:H.duration * Scretch.factor
                            instrument:H.instrument)
                    end
                else
                    "StretchTrans: Error"
                end
            end
        in
            ExtendedPartition = {PartitionToTimedList ScretchTuple.1|nil}
            {Helper ScretchTuple ExtendedPartition}
        end
    end

    fun {DroneTrans DroneTuple}
        local ExtendedPartition
            fun {Helper Partition Amount Acc}
                if Amount == Acc then
                    Partition|nil 
                else
                    Partition|{Helper Partition Amount (Acc+1)}
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
            [] duration(1:P duration:D) then
                {DurationTrans H}|{PartitionToTimedList T}
            [] drone(note:_ amount:_) then
                {DroneTrans H}|{PartitionToTimedList T}
            else
                {NoteToExtended H}|{PartitionToTimedList T}
            end
        else
            "input invalide"
        end
    end

  

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
    {Browse ListOfNotes}
    List = {ChordToExtended ListOfNotes}
    {Browse List}
    PartitionChord = c4|b#4|ListOfNotes|nil
   
    {Browse {PartitionToTimedList PartitionChord}}

    Tuple = stretch(factor:4.0 1:ListOfNotes)
    {Browse Tuple}

    % {Browse {PartitionToTimedList Tuple.1|nil}}
    {Browse {StretchTrans Tuple}}
    {Browse {PartitionToTimedList Tuple|drone(note:a amount:4)|nil}}
end



