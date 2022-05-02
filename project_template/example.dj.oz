local

    Tune = [b b c5 d5 d5 c5 b a g g a b]
    End1 = [stretch(factor:1.5 [b]) drone(amount:2 note:a) stretch(factor:2.0 [a])]
    End2 = [stretch(factor:1.5 [a]) stretch(factor:0.5 [g]) stretch(factor:2.0 [g])]
    Interlude = [a a b g a duration(seconds:0.5 [b c5])
                     b g a transpose(semitones:5 [b c5])
                 b a g a stretch(factor:2.0 [d]) ]
 
    % This is not a music.
    Partition = {Flatten [Tune End1 Interlude End2]}
in
    [ repeat(amount:2 1:[partition(Partition)]) reverse([partition(Partition)])]
end