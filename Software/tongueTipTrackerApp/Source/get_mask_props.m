function get_mask_props(varargin)

p = inputParser;
addRequired(p, 'dirlist');
addRequired(p, 'fiducial');
addOptional(p, 'queue', []);
parse(p, varargin{:});
dirlist = p.Results.dirlist;
fiducial = p.Results.fiducial;
queue = p.Results.queue;

% If no queue given, create a dummy queue
if isempty(queue)
    queue = parallel.pool.DataQueue();
    afterEach(queue, @disp);
end

parfor i=1:numel(dirlist)
    send(queue, ['Processing mask properties for session ', dirlist{i}, '...']);
    dirlist_bot = rdir(fullfile(dirlist{i},'Bot*.mat'));
    dirlist_top = rdir(fullfile(dirlist{i},'Top*.mat'));
    [out_xy_bot] = centerofmass_kin(dirlist_bot,fiducial(i).bot);
    [out_xy_top] = centerofmass_kin(dirlist_top,fiducial(i).top);

    outStruct = struct();
    outStruct.out_xy_bot = out_xy_bot;
    outStruct.out_xy_top = out_xy_top;
    
    parsave(fullfile(dirlist{i},'mask_props'), outStruct);
    send(queue, ['...done processing mask properties for session ', dirlist{i}]);
end
