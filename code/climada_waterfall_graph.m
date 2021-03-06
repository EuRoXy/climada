function  fig = climada_waterfall_graph(EDS_today,EDS_dev,EDS_cc,return_period,check_printplot,legend_on)
% NAME:
%   climada_waterfall_graph
% PURPOSE:
%   show waterfall plot expected damage for specific return period to
%   compare
%   - risk today (assets today, hazard today)
%   - increase due to economic development (future assets, hazard today)
%   - increase due to climate change (future assets, future hazard)
%
%   previous call: climada_EDS_calc
% CALLING SEQUENCE:
%   climada_waterfall_graph(EDS_today,EDS_dev,EDS_cc,return_period,check_printplot)
% EXAMPLE:
%   climada_waterfall_graph
% INPUTS:
%   EDS_today: event damage set for risk today (assets today, hazard today)
%       usually generated by climada_EDS_calc
%       if EDS_today is a struct with three elements, the code assumes
%       EDS_today(1) to be real EDS today, EDS_today(2) to be EDS_dev and
%       EDS_today(2) to be EDS_cc
%       > prompted for if not provided (as saved EDS), but this is not
%       recommended, as one easily mixes up EDSs.
%   EDS_dev: event damage set for risk incl. econ. development (future assets, hazard today)
%       > prompted for if not provided (as saved EDS), but this is not
%       recommended, as one easily mixes up EDSs.
%   EDS_cc: event damage set for risk incl. econ. dev. and climate change
%       (future assets, future hazard)
%       > prompted for if not provided (as saved EDS), but this is not
%       recommended, as one easily mixes up EDSs.
% OPTIONAL INPUT PARAMETERS:
%   return_period: the return period for which damages are shown, e.g. =100
%       default (=9999) is annual expected damage (i.e. EDS.ED)
%   check_printplot:if set to 1, figure saved, default 0.
%       if =-1, avoid all the additonal labels etc (for e.g. slides)
%   legend_on: if =1, show legend with entity and hazard names, default=0
% OUTPUTS:
%   waterfall graph
% MODIFICATION HISTORY:
% Lea Mueller, 20110622
% Martin Heynen, 20120329
% David N. Bresch, david.bresch@gmail.com, 20130316 EDS->EDS
% David N. Bresch, david.bresch@gmail.com, 20150419 try-catch for arrow plotting
% Lea Mueller, muellele@gmail.com, 20150831, integrate Value_unit from EDS_today.Value_unit
% David N. Bresch, david.bresch@gmail.com, 20150906 ED as default for return_period
% David N. Bresch, david.bresch@gmail.com, 20150906 font scale and label texts shortened
% David N. Bresch, david.bresch@gmail.com, 20150907 font scale and label texts shortened
% Lea Mueller, muellele@gmail.com, 20150930, introduce climada_digit_set
% Lea Mueller, muellele@gmail.com, 20151020, add TIV for future reference year
% Lea Mueller, muellele@gmail.com, 20151030, bugfix in climada_arrow
% Lea Mueller, muellele@gmail.com, 20151209, set no_fig=1, add legend_on=1
% David N. Bresch, david.bresch@gmail.com, 20160524, default legend_on=0, some simplifiactions
% David N. Bresch, david.bresch@gmail.com, 20170504, small fix to show correct TIV
% David N. Bresch, david.bresch@gmail.com, 20190620, print to stdout omitted
%-

fig=[]; % init dummy output

global climada_global
if ~climada_init_vars, return; end

% poor man's version to check arguments
if ~exist('EDS_today'      ,'var'), EDS_today = []; end
if ~exist('EDS_dev'        ,'var'), EDS_dev   = []; end
if ~exist('EDS_cc'         ,'var'), EDS_cc    = []; end
if ~exist('return_period'  ,'var'), return_period   = 9999; end
if ~exist('check_printplot','var'), check_printplot = 0; end
if ~exist('legend_on'      ,'var'), legend_on = ''; end

no_fig = 1; % default
if check_printplot>0,no_fig=0;end

if isempty(legend_on), legend_on = 0; end

% prompt for EDS_today if not given
if isempty(EDS_today) % local GUI
    EDS_today_filename=[climada_global.data_dir filesep 'results' filesep '*.mat'];
    [filename, pathname] = uigetfile(EDS_today_filename, 'Select EDS today:');
    if isequal(filename,0) || isequal(pathname,0)
        return; % cancel
    else
        EDS_today_filename=fullfile(pathname,filename);
        load(EDS_today_filename);
        EDS_today=EDS;
    end
end

if length(EDS_today)==1 % holds only one EDS, other parameters must hold further EDSs
    
    % prompt for EDS_dev if not given
    if isempty(EDS_dev) % local GUI
        EDS_dev_filename=[climada_global.data_dir filesep 'results' filesep '*.mat'];
        [filename, pathname] = uigetfile(EDS_dev_filename, 'Select EDS development:');
        if isequal(filename,0) || isequal(pathname,0)
            return; % cancel
        else
            EDS_dev_filename=fullfile(pathname,filename);
            load(EDS_dev_filename);
            EDS_dev=EDS;
        end
    end
    
    % prompt for EDS_cc if not given
    if isempty(EDS_cc) % local GUI
        EDS_cc_filename=[climada_global.data_dir filesep 'results' filesep '*.mat'];
        [filename, pathname] = uigetfile(EDS_cc_filename, 'Select EDS climate change:');
        if isequal(filename,0) || isequal(pathname,0)
            return; % cancel
        else
            EDS_cc_filename=fullfile(pathname,filename);
            load(EDS_cc_filename);
            EDS_cc=EDS;
        end
    end
    
    % convert to one EDS structure
    EDS    = struct([]);
    EDS    = EDS_today;
    EDS(2) = EDS_dev;
    EDS(3) = EDS_cc;
else
    EDS=EDS_today; % contains all three EDSs
end %length(EDS_today)==1

damage=zeros(1,length(EDS)); % init
legend_str=cell(1,length(EDS));

for EDS_i = 1:length(EDS)
    
    % check if annual expected damage is requested
    if return_period == 9999
        damage(EDS_i) = EDS(EDS_i).ED;
    else
        DFC=climada_EDS2DFC(EDS(EDS_i),return_period);
        damage(EDS_i)=DFC.damage;
    end
    
    % identification of EDS_i
    hazard_name       = strtok(EDS(EDS_i).hazard.comment,',');
    hazard_name       = horzcat(hazard_name, ' ', int2str(EDS(EDS_i).reference_year));
    [~, assets_name] = fileparts(EDS(EDS_i).assets.filename);
    str               = sprintf('%s | %s',assets_name, hazard_name);
    str               = strrep(str,'_',' '); % since title is LaTEX format
    str               = strrep(str,'|','\otimes'); % LaTEX format
    legend_str{EDS_i} = str;
end % EDS_i

damage(end+1)           = damage(end); % last one is sum, 2nd last is still shown as a contribution

% set unit string
if isfield(EDS_today,'Value_unit')
    unit_str = EDS_today.Value_unit;
else
    unit_str = climada_global.Value_unit;
end

%digits of damage
[digits, digit_str] = climada_digit_set(damage);
damage = damage*10^-digits;

% TIV of portfolio
[digit_TIV, digit_TIV_str] = climada_digit_set([EDS(1).Value]);
%TIV = unique([EDS(:).Value])*10^-digit_TIV; % until 20170504
TIV = [EDS(:).Value].*10^-digit_TIV;

% set ylabel
if isfield(EDS,'Value_unit')
    Value_unit = EDS.Value_unit;
else
    Value_unit = climada_global.Value_unit;
end
if isempty(digit_str)
    ylabel_str = sprintf('Damage (%s)',Value_unit);
else
    ylabel_str = sprintf('Damage (%s %s)',Value_unit,digit_str);
end

% fontsize_  = 8;
fontsize_  = 12*climada_global.font_scale;
fontsize_2 = fontsize_ - 3;
fontsize_3  = 12; % does not scale, since additional labels
stretch    = 0.3;

if ~no_fig
    fig = climada_figuresize(0.57,0.7);
end
% yellow - red color scheme
color_     = [255 215   0 ;...   %today
    255 127   0 ;...   %eco
    238  64   0 ;...   %clim
    205   0   0 ;...   %total risk
    120 120 120]/256;  %dotted line]/255;
color_(1:4,:) = brighten(color_(1:4,:),0.3);

% % green color scheme
% color_     = [227 236 208;...   %today
%               194 214 154;...   %eco
%               181 205  133;...  %clim
%               197 190 151;...   %total risk
%               120 120 120]/256; %dotted line]/255;
% color_(1:4,:) = brighten(color_(1:4,:),-0.5);

damage_count = length(damage);
damage       = [0 damage];

hold on
area([damage_count-stretch damage_count+stretch], damage(4)*ones(1,2),'facecolor',color_(4,:),'edgecolor','none')
for i = 1:length(damage)-2
    h(i) = patch( [i-stretch i+stretch i+stretch i-stretch],...
        [damage(i) damage(i) damage(i+1) damage(i+1)],...
        color_(i,:),'edgecolor','none');
end
for i = 1:length(damage)-2
    if i==1
        plot([i+stretch 4+stretch],[damage(i+1) damage(i+1)],':','color',color_(5,:))
    else
        plot([i+stretch 4-stretch],[damage(i+1) damage(i+1)],':','color',color_(5,:))
    end
end

%number of digits before the comma (>10) or behind the comma (<10)
damage_disp(1) = damage(2);
damage_disp(2) = damage(3)-damage(2);
damage_disp(3) = damage(4)-damage(3);
damage_disp(4) = damage(4);

if max(damage)>100
    N = -abs(floor(log10(max(damage)))-1);
    N = 0;
    damage_disp = round(damage_disp*10^N)/10^N;
    N = 0;
else
    %N = round(log10(max(damage_disp)));
    N = 2;
end

%damages above bars
strfmt = ['%2.' int2str(N) 'f'];
dED = 0.0;
text(1, damage(2)                     , num2str(damage_disp(1),strfmt), 'color','k', 'HorizontalAlignment','center', 'VerticalAlignment','bottom','FontWeight','bold','fontsize',fontsize_);
text(2-dED, damage(2)+ (damage(3)-damage(2))/2, num2str(damage_disp(2),strfmt), 'color','w', 'HorizontalAlignment','center', 'VerticalAlignment','middle','FontWeight','bold','fontsize',fontsize_);
text(3-dED, damage(3)+ (damage(4)-damage(3))/2, num2str(damage_disp(3),strfmt), 'color','w', 'HorizontalAlignment','center', 'VerticalAlignment','middle','FontWeight','bold','fontsize',fontsize_);
text(4, damage(4)                     , num2str(damage_disp(4),strfmt), 'color','k', 'HorizontalAlignment','center', 'VerticalAlignment','bottom','FontWeight','bold','fontsize',fontsize_);

%remove xlabels and ticks
set(gca,'xticklabel',[],'FontSize',10,'XTick',zeros(1,0),'layer','top');

set(gcf,'Color',[1 1 1]); % figure background color white

%axis range and ylabel
xlim([0.5 4.5])
ylim([0   max(damage)*1.25])
ylabel(ylabel_str,'fontsize',fontsize_)
% ylabel(['Damage amount \cdot 10^{', int2str(dig) '}'],'fontsize',fontsize_)

%arrow eco
% dED2 = 0.05;
dED2 = stretch+0.05;
% dED3 = 0.10;
dED3 = stretch+0.07;
try
    climada_arrow ([2+dED2 damage(2)], [2+dED2 damage(3)], 40, 10, 30,'width',1.5,'Length',10, 'BaseAngle',90, 'EdgeColor','none', 'FaceColor',[0.5 0.5 0.5]);
catch
    fprintf('Warning: arrow printing failed in %s (1)\n',mfilename);
end
text (2+dED3, damage(2)+diff(damage(2:3))*0.5, ['+' int2str((damage(3)-damage(2))/damage(2)*100) '%'], ...
    'color',[0. 0. 0.],'HorizontalAlignment','left','VerticalAlignment','middle','fontsize',fontsize_-1);

%arrow cc
try
    climada_arrow ([3+dED2 damage(3)], [3+dED2 damage(4)], 40, 10, 30,'width',1.5,'Length',10, 'BaseAngle',90, 'EdgeColor','none', 'FaceColor',[0.5 0.5 0.5]);
catch
    fprintf('Warning: arrow printing failed in %s (2)\n',mfilename);
end
text (3+dED3, damage(3)+diff(damage(3:4))*0.5, ['+' int2str((damage(4)-damage(3))/damage(2)*100) '%'], ...
    'color',[0. 0. 0.],'HorizontalAlignment','left','VerticalAlignment','middle','fontsize',fontsize_-1);

%arrow total
try
    climada_arrow ([4 damage(2)], [4 damage(4)], 40, 10, 30,'width',1.5,'Length',10, 'BaseAngle',90, 'EdgeColor','none', 'FaceColor',[256 256 256]/256);
catch
    fprintf('Warning: arrow printing failed in %s (3)\n',mfilename);
end
text (4, damage(2)-max(damage)*0.02, ['+' int2str((damage(4)-damage(2))/damage(2)*100) '%'], 'color','w','HorizontalAlignment','center','VerticalAlignment','top','fontsize',fontsize_);


%title
if check_printplot>=0
    if return_period == 9999
        textstr = 'Annual Expected Damage (AED)';
    else
        textstr = ['Expected damage with a return period of ' int2str(return_period) ' years'];
    end
    if strcmp(Value_unit,'people')
        textstr_TIV = sprintf('Total population (%d): %3.1f %s %s',climada_global.present_reference_year,TIV(1),digit_TIV_str,unit_str);
        textstr_TIV_2 = sprintf('Total population (%d): %3.1f %s %s',climada_global.future_reference_year,TIV(2),digit_TIV_str,unit_str);
    else
        textstr_TIV = sprintf('Total assets (%d): %3.1f %s %s',climada_global.present_reference_year,TIV(1),digit_TIV_str,unit_str);
        textstr_TIV_2 = sprintf('Total assets (%d): %3.1f %s %s',climada_global.future_reference_year,TIV(2),digit_TIV_str,unit_str);
    end
    text(1-stretch, max(damage)*1.20,textstr, 'color','k','HorizontalAlignment','left','VerticalAlignment','top','FontWeight','bold','fontsize',fontsize_);
    text(1-stretch, max(damage)*1.15,textstr_TIV, 'color','k','HorizontalAlignment','left','VerticalAlignment','top','FontWeight','normal','fontsize',fontsize_2);
    text(1-stretch, max(damage)*1.10,textstr_TIV_2, 'color','k','HorizontalAlignment','left','VerticalAlignment','top','FontWeight','normal','fontsize',fontsize_2);
end

% if return_period == 9999
%     text(1- stretch, max(damage)*1.2, {'Annual Expected damage (AED)'}, 'color','k','HorizontalAlignment','left','VerticalAlignment','top','FontWeight','bold','fontsize',fontsize_);
%  else
%     text(1- stretch, max(damage)*1.2, ['Expected damage with a return period of ' int2str(return_period) ' years'], 'color','k','HorizontalAlignment','left','VerticalAlignment','top','FontWeight','bold','fontsize',fontsize_);
% end

%xlabel
text(1-stretch, damage(1)-max(damage)*0.02, {'Risk today',['(' num2str(climada_global.present_reference_year) ')']}, 'color','k','HorizontalAlignment','left','VerticalAlignment','top','fontsize',fontsize_2);
text(2-stretch, damage(1)-max(damage)*0.02, {'Economic','development'},'color','k','HorizontalAlignment','left','VerticalAlignment','top','fontsize',fontsize_2);
text(3-stretch, damage(1)-max(damage)*0.02, {'Climate','change'},                                 'color','k','HorizontalAlignment','left','VerticalAlignment','top','fontsize',fontsize_2);
text(4-stretch, damage(1)-max(damage)*0.02, {['Risk ' num2str(climada_global.future_reference_year)]}, 'color','k','HorizontalAlignment','left','VerticalAlignment','top','fontsize',fontsize_2);

%Legend
%L = legend(h,legend_str(index),'location','NorthOutside','fontsize',fontsize_2);
%set(L,'Box', 'off')
if check_printplot>=0
    if legend_on
        L=legend(h, legend_str(index),'Location','NorthEast');
        set(L,'Box', 'off')
        set(L,'Fontsize',fontsize_3)
    end
end
if check_printplot>0
    print(fig,'-dpdf',[climada_global.data_dir foldername])
    fprintf('saved 1 FIGURE in folder %s \n', foldername);
end % check_printplot>=0

end % climada_waterfall_graph