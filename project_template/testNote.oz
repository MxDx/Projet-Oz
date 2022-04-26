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
    Chord

    fun {ChordToExtended Chord}
        case Chord
        of nil then
            nil
        [] H|T then
            {NoteToExtended H}|{ChordToExtended T}
        end
    end

    fun {NoteChordToExtended NoteChord}
        case NoteChord
        of note(name:N octave:O sharp:S duration:D instrument:I) then
            NoteChord
        [] H|T then
            case H
            of note(name:N octave:O sharp:S duration:D instrument:I) then
                H|{NoteChordToExtended T}
            else
                {ChordToExtended H}|{NoteChordToExtended T}
            end
        else
            {NoteToExtended H}|{PartitionToTimedList T}
        end
    end

    fun {PartitionToTimedList Partition}
        case Partition
        of nil then nil
        [] H1|T1 then
            case H1
            of note(name:N octave:O sharp:S duration:D instrument:I) then
                H1|{PartitionToTimedList T1}
            [] H2|T2 then
                case H2
                of note(name:N octave:O sharp:S duration:D instrument:I) then
                    H1|{PartitionToTimedList T1}
                else
                    {ChordToExtended H1}|{PartitionToTimedList T2}
                end
            else
                {NoteToExtended H1}|{PartitionToTimedList T1}
            end
        end
    end

    fun {DurationTransformer Duration}
    end

    % fun {Testsesgrandsmorts Test}
    %     case Test
    %     of note(name:N octave:O sharp:S duration:D instrument:I) then
    %     [] H|T then
    %         case H
    %         of note(name:N octave:O sharp:S duration:D instrument:I) then 4
    %         else
    %             5
    %         end
    %     [] silence(duration:D) then 3
    %     else
    %         0
    %     end
    % end

    Partition
    Stretch
in
    Note = {NoteToExtended c}

    % {Browse Note}
    % SilenceTest = {NoteToExtended 1}
    % {Browse SilenceTest}
    TestChords = a1|a2|b|nil
    Chord = {ChordToExtended TestChords}

    Partition = [b b# [b b] b Note Chord]
    FlattenPartion = {PartitionToTimedList Partition}
    {Browse FlattenPartion}
    % {Browse Note.sharp}
    Stretch = stretch(duration:4.0 [a1])
    {Browse Stretch.1}
    
    % {Browse TestChords}
    % {Browse Chord}
    % {Browse {IsList Chord}}
    % {Browse {List.is Chord}}
    % {Browse {Record.label Note}}
    % {Browse {Record.is TestChords}}
    % {Browse {Record.label TestChords}}
    % {Browse {Record.label Chord}}
    % {Browse {Testsesgrandsmorts Note}}
    % {Browse {Testsesgrandsmorts Chord}}
    % {Browse {Testsesgrandsmorts TestChords}}
    % {Browse {Testsesgrandsmorts a#1}}
end