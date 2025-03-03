% create_brainstem_atlas_group
% 
% Create a brain atlas with anatomically defined region groups, from
% various atlases/papers.  Uses canlab_load_ROI
%
% Notes: functional atlases probably do not [yet] have very good
% subdivisions, and there is a clear demarcation of functions, inputs, and
% outputs by anatomical subnuclei.

% Define: 1 mm space by default, based on HCP image
% This initial image covers the whole space

bstem_atlas = atlas(which('canlab_brainstem.img'));
bstem_atlas = threshold(bstem_atlas, .2);

bstemimg = fmri_data(which('brainstem_mask_tight_2018.img'));
bstem_atlas = apply_mask(bstem_atlas, bstemimg);

% this has some other regions in it (e.g., mammillary bodies), so would be better to use the
% 'noreplace' option when merging it with other atlases.

orthviews(bstem_atlas);

%see also: bstemimg.fullpath = fullfile(pwd, 'brainstem_mask_tight_2018.img');

%%
shen = load_atlas('shen');

shen = apply_mask(shen, bstemimg);

r = atlas2region(shen);
orthviews(shen)
%[r, labels] = cluster_names(r,true);

labels1 = {'xxx' 'Shen_Midb_Rrv' 'Shen_CerPed_R' 'Shen_CerPed_R' 'Shen_CerPed_R' 'xxx' 'xxx' 'xxx'};  % 1:8
%for i = 1:8, orthviews(r(i), {[1 0 0]}); labels1{i}, input(''), end

labels2 = {'xxx' 'Shen_Midb_Rd' 'xxx' 'Shen_Med_R' 'Shen_Pons_R' 'Shen_Pons_Rcv' 'Shen_Midb_R' 'Shen_Pons_Rcd'};
rr = r(9:16);
%for i = 1:8, orthviews(rr(i), {[1 0 0]}); labels2{i}, input(''), end

labels3 = {'xxx' 'xxx' 'Shen_CerPed_L' 'xxx' 'xxx' 'xxx' 'xxx' 'Shen_Pons_Lrd'};
rr = r(17:24);
%for i = 1:8, orthviews(rr(i), {[1 0 0]}); labels3{i}, input(''), end

labels4 = {'xxx' 'xxx' 'xxx' 'Shen_Midb_Ld' 'xxx' 'Shen_Midb_L' 'Shen_Med_L' 'Shen_Pons_Lcd' 'Shen_Pons_L'};
rr = r(25:33);
%for i = 1:9, orthviews(rr(i), {[1 0 0]}); labels4{i}, input(''), end

labels = [labels1 labels2 labels3 labels4];
wh_omit = strcmp(labels, 'xxx');

r(wh_omit) = [];
labels(wh_omit) = [];

shen = remove_atlas_region(shen, find(wh_omit));
shen.labels_3 = shen.labels_2;
shen.labels_2 = shen.labels;
shen.labels = labels;

% to find clusters by hand:
% [~,wh] = find_closest_cluster(r, spm_orthviews('pos')) 

% Reorder Shen regions, leaving out peduncles

[~, left] = select_atlas_subset(shen, {'_L'});
[~, right] = select_atlas_subset(shen, {'_R'});

[~, wh_midb] = select_atlas_subset(shen, {'Midb'});
wh_midb = [find([wh_midb & left]) find([wh_midb & right])];

[~, wh_pons] = select_atlas_subset(shen, {'Pons'});
wh_pons = [find([wh_pons & left]) find([wh_pons & right])];

[~, wh_med] = select_atlas_subset(shen, {'Med'});
wh_med = [find([wh_med & left]) find([wh_med & right])];


wh_order = [wh_midb wh_pons wh_med];

shen = reorder_atlas_regions(shen, wh_order);


%% Add shen brainstem, replacing old ones

bstem_atlas = merge_atlases(bstem_atlas, shen, 'always_replace');




%% add other regions
% ...replacing voxels where new one overlaps

% also include regions in other atlases that we want to remove here - so
% that we remove these voxels

% to-do: 'pbn' 'nts'

regionnames = {'sc' 'ic' 'pag' 'PBP' 'sn' 'VTA' 'rn' 'drn' 'mrn' 'lc' 'rvm'};

% NEW ONES TOO

for i = 1:length(regionnames)
    regionname = regionnames{i};
    
    [~, roi_atlas] = canlab_load_ROI(regionname);
    orthviews(roi_atlas);

    bstem_atlas = merge_atlases(bstem_atlas, roi_atlas, 'always_replace');
    
end

% Fix - not sure why some labels not saving
bstem_atlas.labels(end-2:end) = {'R_LC' 'L_LC' 'rvm'};

atlas_obj = bstem_atlas;

%% save object

atlas_name = 'brainstem_combined';

if dosave
    
    savename = sprintf('%s_atlas_object.mat', atlas_name);
    save(savename, 'atlas_obj');
    
end

%% Turn regions into separate list of names, for canlab_load_ROI
% which loads regions by name from mat files.

clear region_names

r = atlas2region(atlas_obj);
labels = atlas_obj.labels;

for i = 1:length(r)
    
    eval([labels{i} ' = r(i);']);
    
    region_names{i} = r(i).shorttitle;
    
end

savename = sprintf('%s_atlas_regions.mat', atlas_name);
save(savename, 'r', 'region_names', labels{:});

%%
if dosave
    
    figure; han = isosurface(atlas_obj);
    
    set(han,'FaceAlpha', .5)
    view(135, 20)
    lightFollowView;
    lightRestoreSingle
    axis off
    
    savename = fullfile(savedir, sprintf('%s_isosurface.png', atlas_name));
    saveas(gcf, savename);
    
end

 %% save figure

if dosave
   
    o2 = canlab_results_fmridisplay([], 'multirow', 1);
    brighten(.6)
    
    o2 = montage(r, o2, 'wh_montages', 1:2);
    
    savedir = fullfile(pwd, 'png_images');
    if ~exist(savedir, 'dir'), mkdir(savedir); end
    
    scn_export_papersetup(600);
    savename = fullfile(savedir, sprintf('%s_montage.png', atlas_name));
    saveas(gcf, savename);

end
 