local
   % See project statement for API details.
   % !!! Please remove CWD identifier when submitting your project !!!
   CWD = 'project_template/' % Put here the **absolute** path to the project files
   [Project] = {Link [CWD#'Project2022.ozf']}
   Time = {Link ['x-oz://boot/Time']}.1.getReferenceTime

   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

   % Translate a note to the extended notation.
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

   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

   % Function that works with PartitionToTimedList :
   % It adds elements of the list List in the final TimedList without the nil.
   % Once all elements of the list List are added, the function calls 
   % PartitionToTimedList on the tail Tail
   fun {AddTogether List Tail}
      case List
      of nil then
          {PartitionToTimedList Tail} 
      [] H|T then 
          H|{AddTogether T Tail}
      end
  end

   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

   % function that processes a Duration Record into a timed list
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

   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   
   % Function that processes a Stretch Record into a Timed List
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

   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

   % Function that processes a Drone Record into a Timed List
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

   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

   % Fonction nécessaire au fonctionnement de TransposeTrans
   % Fonction qui calcule et retourne le nouvel octave atteint lorsqu'on transpose une note
   % de TransValue semi-tons vers le haut ou vers le bas et qui stock l'entier
   % correspondant a la nouvelle note atteinte dans IntNoteName
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

   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

   % Fonction that processes a transpose record into a Timed List
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

 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

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

   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

   fun {Mix P2T Music}
      % TODO
      {Project.readFile CWD#'wave/animals/cow.wav'}
   end

   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

   Music = {Project.load CWD#'joy.dj.oz'}
   Start

   % Uncomment next line to insert your tests.
   % \insert '/full/absolute/path/to/your/tests.oz'
   % !!! Remove this before submitting.
in
   Start = {Time}

   % Uncomment next line to run your tests.
   % {Test Mix PartitionToTimedList}

   % Add variables to this list to avoid "local variable used only once"
   % warnings.
   {ForAll [NoteToExtended Music] Wait}
   
   % Calls your code, prints the result and outputs the result to `out.wav`.
   % You don't need to modify this.
   {Browse {Project.run Mix PartitionToTimedList Music 'out.wav'}}
   
   % Shows the total time to run your code.
   {Browse {IntToFloat {Time}-Start} / 1000.0}
end
