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

    % fun {Transpose NoteTuple Amount} 
    %     local Index SharpTones OrderOfTones
    %         fun {HelperFind Note OrderOfTones Acc}
    %             case OrderOfTones
    %             of H|T then
    %                 if Note == H then Acc
    %                 elseif {Member H SharpTones} then
    %                     {HelperFind Note T (Acc+2)}
    %                 else
    %                     {HelperFind Note T (Acc+1)}
    %                 end
    %             else
    %                 ~6
    %             end
    %         end
    %         fun {HelperTranspose Index NoteTuple Amount Acc}
    %             if Acc == Amount then NoteTuple
    %             elseif {Member NoteTuple.name SharpTones} then
    %                 if NoteTuple.sharp then
    %                     {HelperTranspose Index+1 note(name:NoteTuple.name
    %                                             octave:NoteTuple.octave
    %                                             sharp:false
    %                                             duration:NoteTuple.duration
    %                                             instrument:NoteTuple.instrument) Amount (Acc+1)}
    %                 else
    %                     {HelperTranspose Index+1 note(name:{Nth OrderOfTones Index+1}
    %                                             octave:NoteTuple.octave
    %                                             sharp:true
    %                                             duration:NoteTuple.duration
    %                                             instrument:NoteTuple.instrument) Amount (Acc+1)}
    %                 end
    %             else
    %                 if NoteTuple.name == b then
    %                     {HelperTranspose 0 note(name:c
    %                                             octave:NoteTuple.octave
    %                                             sharp:false
    %                                             duration:NoteTuple.duration
    %                                             instrument:NoteTuple.instrument) Amount (Acc+1)}
    %                 else
    %                     {HelperTranspose Index+1 note(name:{Nth OrderOfTones Index+1}
    %                                             octave:NoteTuple.octave
    %                                             sharp:false
    %                                             duration:NoteTuple.duration
    %                                             instrument:NoteTuple.instrument) Amount (Acc+1)}
    %                 end
    %             end
    %         end
    %     in 
    %         OrderOfTones = c|d|e|f|g|a|b|nil 
    %         SharpTones = c|d|f|g|a|b|nil
    %         {HelperTranspose {HelperFind Note.name OrderOfTones 0} NoteTuple Amount 0}
    %     end
    % end
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
        %Notes = c|c#|d|d#|e|f|f#|g|g#|a|a#|b
        %Correspond aux nombres 1|2|3|4|5|...|12
        NotestoInt = nti(c:1 d:3 e:5 f:6 g:8 a:10 b:12)
        InttoNote = itn(1:c#false 2:c#true 3:d#false 4:d#true 5:e#false 6:f#false 7:f#true 8:g#false 9:g#true 10:a#false 11:a#true 12:b#false)
        local
            ExtendedPartition
            NoteValue
            TransposedNote
            Octave
            NewName
            fun {Helper Semitone Partition}
                case Partition
                of nil then 
                    nil
                [] H|T then
                    case H
                    of _|_ then
                        {Helper Semitone H}|{Helper Semitone T}
                    else
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
                            sharp:((InttoNote.NewName).2))
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

    fun {MixCalcul Note}
        local NotestoInt H F
            fun {Helper Amount Acc}
                if Amount == Acc then
                    nil
                else
                    0.5 * {Float.sin ((2.0*3.14159265359*{IntToFloat Acc})/44100.0)}|{Helper Amount Acc+1}
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
            {Helper {FloatToInt Note.duration*44100.0} 0}
        end
    end

    % fun {Mix P2T Music}
    %     local
    %         fun {Helper Partition}
    %             case Partition
    %             of nil then
    %                 nil
    %             [] H|T then
    %                 case H
    %                 of _|_ then
    %                     {Helper H}|{Helper T}
    %                 else
    %                     {MixTrans H}|{MixTrans T}
    %                 end
    %             [] note(duration:_ instrument:_ name:_ octave:_ sharp:_)
    %             else
    %                 ~1
    %             end
    %         end
    %     in 
    %         {Helper {P2T Music.1.1}}
    %     end
    % end

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
    CWD = 'project_template/' % Put here the **absolute** path to the project files
    [Project] = {Link [CWD#'Project2022.ozf']}
    Music = {Project.load CWD#'joy.dj.oz'}
    {Browse 0}
    ListOfNotes = (c4|b#6|nil)
    % {Browse ListOfNotes}
    % List = {ChordToExtended ListOfNotes}
    % {Browse List}
    PartitionChord = c4|b#4|ListOfNotes|a|nil

    % {Browse Music.1.1}
    % {Browse {PartitionToTimedList Music.1.1}}
    % {Browse {Project.readFile CWD#'/wave/animals/cow.wav'}}
    {Browse {MixCalcul {NoteToExtended c#5}}}

    % {Browse {PartitionToTimedList PartitionChord}}

    % {Browse {Nth PartitionChord 3}}
    % {Browse {TransposeTrans tupl(1:a4|nil semitones:4)}}
   
    %%%% Test Duration
    %DurationTuple = duration(1:PartitionChord seconds:6.0)
    %PartitionToTest = DurationTuple|nil
    %DurationTuple2 = duration(1:PartitionToTest seconds:2.0)
    %{Browse {PartitionToTimedList PartitionToTest}}
    % {Browse {PartitionToTimedList DurationTuple2|nil}}

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



