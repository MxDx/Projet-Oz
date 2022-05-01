declare
local
    fun {Mix P2T Music}
        % TODO
        {Project.readFile CWD#'wave/animals/cow.wav'}
    end
in
    CWD = 'project_template/' % Put here the **absolute** path to the project files
    [Project] = {Link [CWD#'Project2022.ozf']}
    Music = {Project.load CWD#'joy.dj.oz'}
end