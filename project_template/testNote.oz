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
            H = {NoteToExtended H}
            H|{ChordToExtended T}
        end
    end
    Chord

in
    Note = {NoteToExtended c}
    {Browse Note}
    % SilenceTest = {NoteToExtended silence}
    % {Browse SilenceTest}
    TestChords = a1|a2|a3|a4|nil

    {Browse TestChords}
    Chord = {ChordToExtended TestChords}
    {Browse Chord}
end