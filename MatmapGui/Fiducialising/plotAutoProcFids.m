function autoProcFig = plotAutoProcFids(varargin)
%this function opens the 4th window and deals with everything related to it


if nargin > 1 % if callback of winAutoProcessing is to be executed
    feval(varargin{1},varargin{2:end});  % execute callback
else
 %   setUpAllForTesting
   autoProcFig = Init; % else initialize and open winAutoProcessing.fig
end


function autoProcFig = Init

autoProcFig=winAutoProcessing;
initSomeStartBasics(autoProcFig)

InitFiducials(autoProcFig)
initDisplayButtons(autoProcFig)
setupDisplay(autoProcFig);
UpdateDisplay;


%%%%%%% functions %%%%%%%%%%%%%%%%%%%%%%


function initSomeStartBasics(fig)
% initialize everything that doesn't fit in a specific category
global AUTOPROCESSING
%%%% set up all buttonPress callbacks
set(fig,'WindowButtonDownFcn','plotAutoProcFids(''ButtonDown'',gcbf)',...
   'WindowButtonMotionFcn','plotAutoProcFids(''ButtonMotion'',gcbf)',...
   'WindowButtonUpFcn','plotAutoProcFids(''ButtonUp'',gcbf)',...
   'pointer','arrow');

%%%% set up the listeners for the sliders
sliderx=findobj(allchild(fig),'tag','SLIDERX');
slidery=findobj(allchild(fig),'tag','SLIDERY');

addlistener(sliderx,'ContinuousValueChange',@UpdateSlider);
addlistener(slidery,'ContinuousValueChange',@UpdateSlider);



%%%% init AUTOPROCESSING
AUTOPROCESSING.CurrentEventIdx=[];
AUTOPROCESSING.ZOOMBOX=[];



function initDisplayButtons(fig)
% initialize everything in figure exept the plotting stuff.. 
global AUTOPROCESSING



%%%% set up number of faulty beats text bar
numFaultyBeats = length(AUTOPROCESSING.faultyBeatIndeces);
numBeatsTextObj = findobj(allchild(fig),'Tag','NUMFAULTYBEATS');
numBeatsTextObj.String = num2str(numFaultyBeats);

%%%% set up treshold var edit text 
obj = findobj(allchild(fig),'Tag','TRESHOLD_VAR');
obj.String = num2str(AUTOPROCESSING.TRESHOLD_VAR);

%%%% set up beatSelection popup menu
beatSelectPopupObj = findobj(allchild(fig),'Tag','SELFAULTYBEAT');

if numFaultyBeats == 0  % if no faulty beats
    selectionChoises ='no faulty beats';
    beatSelectPopupObj.Value = 1;
else
     selectionChoises = {};   
    for num = 1:numFaultyBeats
        selectionChoises{num} = num2str(AUTOPROCESSING.faultyBeatIndeces(num)-1);
    end
    %%%% if popubObj has wrong Value, fix it
    if beatSelectPopupObj.Value > numFaultyBeats || beatSelectPopupObj.Value < 1
        beatSelectPopupObj.Value = 1;
    end   
end
beatSelectPopupObj.String = selectionChoises;




function setupDisplay(fig)
%      no plotting, but everything else with axes, particualrely:
%         - sets up some start values for xlim, ylim, sets up axes and slider handles
%         - makes the FD.SIGNAL values,   (RMS and scaling of potvals)
pointer=fig.Pointer;
fig.Pointer='watch';

global TS myScriptData AUTOPROCESSING;

tsindex = myScriptData.unslicedDataIndex;
numframes = size(TS{tsindex}.potvals,2);
AUTOPROCESSING.TIME = [1:numframes]*(1/myScriptData.SAMPLEFREQ);


%%%% set x and y axes limits in plot if this has not been done yet
if ~isfield(AUTOPROCESSING,'XLIM') || ~isfield(AUTOPROCESSING,'YLIM')
    AUTOPROCESSING.XLIM = [1 numframes]*(1/myScriptData.SAMPLEFREQ);
    AUTOPROCESSING.XWIN = [median([0 AUTOPROCESSING.XLIM]) median([3000/myScriptData.SAMPLEFREQ AUTOPROCESSING.XLIM])];
end

AUTOPROCESSING.AXES = findobj(allchild(fig),'tag','AXES');
AUTOPROCESSING.XSLIDER = findobj(allchild(fig),'tag','SLIDERX');
AUTOPROCESSING.YSLIDER = findobj(allchild(fig),'tag','SLIDERY');


% if no groups to display are selected yet (because e.g. first call) -> select all groups to display for autoprocessing
if ~isfield(myScriptData,'DISPLAYGROUPA')
    myScriptData.DISPLAYGROUPA=1:length(myScriptData.GROUPNAME{myScriptData.CURRENTRUNGROUP});
end



groups = myScriptData.DISPLAYGROUPA;
numgroups = length(groups);

AUTOPROCESSING.NAME ={};
AUTOPROCESSING.GROUPNAME = {};
AUTOPROCESSING.GROUP = [];
AUTOPROCESSING.COLORLIST = {[1 0 0],[0 0.7 0],[0 0 1],[0.5 0 0],[0 0.3 0],[0 0 0.5],[1 0.3 0.3],[0.3 0.7 0.3],[0.3 0.3 1],[0.75 0 0],[0 0.45 0],[0 0 0.75]};

%%%% select "show global RMS", if nothing else has been selected yet
if ~isfield(myScriptData,'DISPLAYTYPEA')
    myScriptData.DISPLAYTYPEA=1;
end
%%%% set up signals for global RMS, GROUP RMS or individual RMS
switch myScriptData.DISPLAYTYPEA
    case 1   % show global RMS
        ch  = []; 
        for p=groups 
            leads = myScriptData.GROUPLEADS{myScriptData.CURRENTRUNGROUP}{p};
            index = TS{tsindex}.leadinfo(leads)==0;  % index of only the 'good' leads, filter out badleads
            ch = [ch leads(index)];   % ch is leads only of the leads of the groubs selected, not of all leads
        end
        
        AUTOPROCESSING.SIGNAL = sqrt(mean(TS{tsindex}.potvals(ch,:).^2));
        AUTOPROCESSING.SIGNAL = AUTOPROCESSING.SIGNAL-min(AUTOPROCESSING.SIGNAL);
        AUTOPROCESSING.LEADINFO = 0;
        AUTOPROCESSING.GROUP = 1;
        AUTOPROCESSING.LEAD = 0;
        AUTOPROCESSING.LEADGROUP = 0;
        AUTOPROCESSING.NAME = {'Global RMS'};
        AUTOPROCESSING.GROUPNAME = {'Global RMS'};

        
        set(findobj(allchild(fig),'tag','FIDSGLOBAL'),'enable','on'); 
        set(findobj(allchild(fig),'tag','FIDSLOCAL'),'enable','off');
        if AUTOPROCESSING.SELFIDS > 1
            AUTOPROCESSING.SELFIDS = 1;
            set(findobj(allchild(fig),'tag','FIDSGLOBAL'),'value',1);
            set(findobj(allchild(fig),'tag','FIDSLOCAL'),'value',0);
        end

    case 2
        AUTOPROCESSING.SIGNAL = zeros(numgroups,numframes);
        for p=1:numgroups
            leads = myScriptData.GROUPLEADS{myScriptData.CURRENTRUNGROUP}{groups(p)};
            index = TS{tsindex}.leadinfo(leads)==0;
            AUTOPROCESSING.SIGNAL(p,:) = sqrt(mean(TS{tsindex}.potvals(leads(index),:).^2)); 
            AUTOPROCESSING.SIGNAL(p,:) = AUTOPROCESSING.SIGNAL(p,:)-min(AUTOPROCESSING.SIGNAL(p,:));
            AUTOPROCESSING.NAME{p} = [myScriptData.GROUPNAME{myScriptData.CURRENTRUNGROUP}{groups(p)} ' RMS']; 
        end
        AUTOPROCESSING.GROUPNAME = AUTOPROCESSING.NAME;
        AUTOPROCESSING.GROUP = 1:numgroups;
        AUTOPROCESSING.LEAD = 0*AUTOPROCESSING.GROUP;
        AUTOPROCESSING.LEADGROUP = groups;
        AUTOPROCESSING.LEADINFO = zeros(numgroups,1);

        set(findobj(allchild(fig),'tag','FIDSGLOBAL'),'enable','on');
        set(findobj(allchild(fig),'tag','FIDSLOCAL'),'enable','off');
        if AUTOPROCESSING.SELFIDS > 2
            AUTOPROCESSING.SELFIDS = 1;
            set(findobj(allchild(fig),'tag','FIDSGLOBAL'),'value',1);
            set(findobj(allchild(fig),'tag','FIDSLOCAL'),'value',0);
        end

    case 3   % indiv fids
        
        
        %%%% only for autoprocessing, make copy of GROUPLEADS, where the groupleads, that are not in leadsToAutoprocess, are filtered out. Only work with the copies here       
        GROUPLEADS=myScriptData.GROUPLEADS{myScriptData.CURRENTRUNGROUP};   %the copy
        for group=groups
            GROUPLEADS{group}=intersect(AUTOPROCESSING.leadsToAutoprocess, GROUPLEADS{group});
        end
        
        
        
        AUTOPROCESSING.GROUP =[];
        AUTOPROCESSING.NAME = {};
        AUTOPROCESSING.LEAD = [];
        AUTOPROCESSING.LEADGROUP = [];
        ch  = []; 
        for p=groups
            ch = [ch GROUPLEADS{p}]; 
            AUTOPROCESSING.GROUP = [AUTOPROCESSING.GROUP p*ones(1,length(GROUPLEADS{p}))];
            AUTOPROCESSING.LEADGROUP = [AUTOPROCESSING.GROUP GROUPLEADS{p}];
            AUTOPROCESSING.LEAD = [AUTOPROCESSING.LEAD GROUPLEADS{p}];
            for q=1:length(GROUPLEADS{p})
                AUTOPROCESSING.NAME{end+1} = sprintf('# %d',GROUPLEADS{p}(q)); 
            end 
        end
        for p=1:length(groups)
            AUTOPROCESSING.GROUPNAME{p} = [myScriptData.GROUPNAME{myScriptData.CURRENTRUNGROUP}{groups(p)}]; 
        end
        AUTOPROCESSING.SIGNAL = TS{tsindex}.potvals(ch,:);
        AUTOPROCESSING.LEADINFO = TS{tsindex}.leadinfo(ch);

        set(findobj(allchild(fig),'tag','FIDSGLOBAL'),'enable','on');
        set(findobj(allchild(fig),'tag','FIDSGROUP'),'enable','on');
        set(findobj(allchild(fig),'tag','FIDSLOCAL'),'enable','on');
end


%%%% if no scaling has been selected yet, choose "local" as the default
if ~isfield(myScriptData,'DISPLAYSCALINGA')
    myScriptData.DISPLAYSCALINGA=1;
end
%%%% modify signal accourding to chosen Displayscaling
switch myScriptData.DISPLAYSCALINGA
    case 1
        k = max(abs(AUTOPROCESSING.SIGNAL),[],2);
        [m,~] = size(AUTOPROCESSING.SIGNAL);
        k(k==0) = 1;
        s = sparse(1:m,1:m,1./k,m,m);
        AUTOPROCESSING.SIGNAL = s*AUTOPROCESSING.SIGNAL;
    case 2
        k = max(abs(AUTOPROCESSING.SIGNAL(:)));
        [m,~] = size(AUTOPROCESSING.SIGNAL);
        if k > 0
            s = sparse(1:m,1:m,1/k*ones(1,m),m,m);
            AUTOPROCESSING.SIGNAL = s*AUTOPROCESSING.SIGNAL;
        end
    case 3
        [m,~] = size(AUTOPROCESSING.SIGNAL);
        k = ones(m,1);
        for p=groups
            ind = find(AUTOPROCESSING.GROUP == p);
            k(ind) = max(max(abs(AUTOPROCESSING.SIGNAL(ind,:)),[],2));
        end
        s = sparse(1:m,1:m,1./k,m,m);
        AUTOPROCESSING.SIGNAL = s*AUTOPROCESSING.SIGNAL;
end

% if individuals are displayed, give signals an offset, so they dont touch
% in plot
if myScriptData.DISPLAYTYPEA == 3
    AUTOPROCESSING.SIGNAL = 0.5*AUTOPROCESSING.SIGNAL+0.5;
end

numsignal = size(AUTOPROCESSING.SIGNAL,1);
for p=1:numsignal   % stack signals "on top of each other" for plotting..
    AUTOPROCESSING.SIGNAL(p,:) = AUTOPROCESSING.SIGNAL(p,:)+(numsignal-p);
end
AUTOPROCESSING.YLIM = [0 numsignal];
AUTOPROCESSING.YWIN = [max([0 numsignal-6]) numsignal]; %dipsplay maximal 6 singnals simulatniouslyy

fig.Pointer=pointer;

function UpdateDisplay
%plots the FD.SIGNAL,  makes the plot..  also calls  DisplayFiducials
global myScriptData AUTOPROCESSING;
ax=AUTOPROCESSING.AXES;
axes(ax);
cla(ax);
hold(ax,'on');
ywin = AUTOPROCESSING.YWIN;
xwin = AUTOPROCESSING.XWIN;
xlim = AUTOPROCESSING.XLIM;
ylim = AUTOPROCESSING.YLIM;

numframes = size(AUTOPROCESSING.SIGNAL,2);
startframe = max([floor(myScriptData.SAMPLEFREQ*xwin(1)) 1]);
endframe = min([ceil(myScriptData.SAMPLEFREQ*xwin(2)) numframes]);

%%%% DRAW THE GRID
if ~isfield(myScriptData,'DISPLAYGRIDA')
    myScriptData.DISPLAYGRIDA=1;  % default is "no grid", if nothing else has been selected so far
end
if myScriptData.DISPLAYGRIDA > 1
    if myScriptData.DISPLAYGRIDA > 2
        clines = 0.04*[floor(xwin(1)/0.04):ceil(xwin(2)/0.04)];
        X = [clines; clines]; Y = ywin'*ones(1,length(clines));
        line(ax,X,Y,'color',[0.9 0.9 0.9],'hittest','off');
    end
    clines = 0.2*[floor(xwin(1)/0.2):ceil(xwin(2)/0.2)];
    X = [clines; clines]; Y = ywin'*ones(1,length(clines));
    line(ax,X,Y,'color',[0.5 0.5 0.5],'hittest','off');
end



numchannels = size(AUTOPROCESSING.SIGNAL,1);



%%%% if no scaling has been selected yet, choose "local" as the default
if ~isfield(myScriptData,'DISPLAYSCALINGA')
    myScriptData.DISPLAYSCALINGA=1;
end


%%%% if offset on/off has not been selected yet, choose 'on' as the default
if ~isfield(myScriptData,'DISPLAYOFFSETA')
    myScriptData.DISPLAYOFFSETA=1;
end

%%%% set up some stuff for offset
if myScriptData.DISPLAYOFFSETA == 1
    chend = numchannels - max([floor(ywin(1)) 0]);
    chstart = numchannels - min([ceil(ywin(2)) numchannels])+1;
else
    chstart = 1;
    chend = numchannels;
end


%%%% if "show label" has not been selected yet for autoprocessing
if ~isfield(myScriptData,'DISPLAYLABELA')
    myScriptData.DISPLAYLABELA=1;
end



%%%% choose colors and plot
for p=chstart:chend
    k = startframe:endframe;
    color = AUTOPROCESSING.COLORLIST{AUTOPROCESSING.GROUP(p)};
    if AUTOPROCESSING.LEADINFO(p) > 0
        color = [0 0 0];
        if AUTOPROCESSING.LEADINFO(p) > 3
            color = [0.35 0.35 0.35];
        end
    end
    plot(ax,AUTOPROCESSING.TIME(k),AUTOPROCESSING.SIGNAL(p,k),'color',color,'hittest','off');
    if (myScriptData.DISPLAYLABELA == 1)&&(chend-chstart < 30) && (AUTOPROCESSING.YWIN(2) >= numchannels-p+1)
        text(ax,AUTOPROCESSING.XWIN(1),numchannels-p+1,AUTOPROCESSING.NAME{p},'color',color,'VerticalAlignment','top','hittest','off'); 
    end
end
set(AUTOPROCESSING.AXES,'YTick',[],'YLim',ywin,'XLim',xwin);

%%%% do some slider stuff
xlen = (xlim(2)-xlim(1)-xwin(2)+xwin(1));
if xlen < (1/myScriptData.SAMPLEFREQ), xslider = 0.99999; else xslider = (xwin(1)-xlim(1))/xlen; end
if xlen >= (1/myScriptData.SAMPLEFREQ), xfill = (xwin(2)-xwin(1))/xlen; else xfill = myScriptData.SAMPLEFREQ; end
xinc = median([(1/myScriptData.SAMPLEFREQ) xfill/2 0.99999]);
xfill = median([(1/myScriptData.SAMPLEFREQ) xfill myScriptData.SAMPLEFREQ]);
xslider = median([0 xslider 0.99999]);
set(AUTOPROCESSING.XSLIDER,'value',xslider,'sliderstep',[xinc xfill]);

ylen = (ylim(2)-ylim(1)-ywin(2)+ywin(1));
if ylen < (1/myScriptData.SAMPLEFREQ), yslider = 0.99999; else yslider = ywin(1)/ylen; end
if ylen >= (1/myScriptData.SAMPLEFREQ), yfill = (ywin(2)-ywin(1))/ylen; else yfill =myScriptData.SAMPLEFREQ; end
yinc = median([(1/myScriptData.SAMPLEFREQ) yfill/2 0.99999]);
yfill = median([(1/myScriptData.SAMPLEFREQ) yfill myScriptData.SAMPLEFREQ]);
yslider = median([0 yslider 0.99999]);
set(AUTOPROCESSING.YSLIDER,'value',yslider,'sliderstep',[yinc yfill]);

%%%% set all handle lists empty (no lines/patches displaying the fids yet)
for beatNumber=1:length(AUTOPROCESSING.allFids)
    AUTOPROCESSING.EVENTS{beatNumber}{1}.handle = [];
    AUTOPROCESSING.EVENTS{beatNumber}{2}.handle = [];
    AUTOPROCESSING.EVENTS{beatNumber}{3}.handle = [];
end

%%%% plot the beatNumber as text
for beatNumber=1:length(AUTOPROCESSING.allFids)
    %first check if beat is within window
    beatStart = AUTOPROCESSING.beats{beatNumber}(1)/myScriptData.SAMPLEFREQ;
    beatEnd = AUTOPROCESSING.beats{beatNumber}(2)/myScriptData.SAMPLEFREQ;
    distance = beatEnd - beatStart;
    if beatStart > AUTOPROCESSING.XWIN(2) || beatEnd < AUTOPROCESSING.XWIN(1)
        continue   % beat is not in window, so don't plot it.
    end
    
    % now plot the text
    if beatNumber == 1
        txt = 'original beat';
    else
        txt=sprintf('beat %d',beatNumber-1);
    end
    text(beatStart + distance/2,AUTOPROCESSING.YWIN(2),txt,'VerticalAlignment','top','HorizontalAlignment','center','FontSize',17)   
end



DisplayFiducials;



function DisplayFiducials
% this functions plotts the lines/patches when u select the fiducials
% (the line u can move around with your mouse)

global myScriptData AUTOPROCESSING;
ywin = AUTOPROCESSING.YWIN;
for beatNumber=1:length(AUTOPROCESSING.EVENTS)   %for each beat
    
    %%%% first check if beat is within window, othterwise its not necessary to plot that beat  
    beatStart = AUTOPROCESSING.beats{beatNumber}(1)/myScriptData.SAMPLEFREQ;
    beatEnd = AUTOPROCESSING.beats{beatNumber}(2)/myScriptData.SAMPLEFREQ;
    
    if beatStart > AUTOPROCESSING.XWIN(2) || beatEnd < AUTOPROCESSING.XWIN(1)
        continue   % beat is not in window, so don't plot it.
    end
    
    %%%% mark the faulty fiducials by plotting red lines where they are
    faultyBeatIndex = find(AUTOPROCESSING.faultyBeatIndeces == beatNumber); 
    if ~isempty(faultyBeatIndex)
        for faultyFidIndex = 1:length(AUTOPROCESSING.faultyBeatValues{faultyBeatIndex})
            x_value = AUTOPROCESSING.faultyBeatValues{faultyBeatIndex}(faultyFidIndex)/myScriptData.SAMPLEFREQ;
            lineObj = line('Parent',AUTOPROCESSING.AXES,'Xdata',[x_value x_value],'Ydata',ywin,'Color','r','hittest','off','LineWidth',3,'LineStyle','-');
            % save the handle
            AUTOPROCESSING.faultyBeatLineHandles{faultyBeatIndex}(faultyFidIndex) = lineObj;
        end
    end
    
    %%%% GLOBAL EVENTS
    events = AUTOPROCESSING.EVENTS{beatNumber}{1};
     if ~isempty(events.handle), index = find(ishandle(events.handle(:)) & (events.handle(:) ~= 0)); delete(events.handle(index)); end   %delete any existing lines
    events.handle = [];

    if AUTOPROCESSING.SELFIDS == 1, colorlist = events.colorlist; else colorlist = events.colorlistgray; end

    for p=1:size(events.value,2)   %   for p=[1: anzahl zu plottender linien]
        switch events.typelist(events.type(p))
            case 1 % normal fiducial
                v = events.value(1,p,1);
                events.handle(1,p) = line('parent',events.axes,'Xdata',[v v],'Ydata',ywin,'Color',colorlist{events.type(p)},'hittest','off','linewidth',events.linewidth{events.type(p)},'linestyle',events.linestyle{events.type(p)});
            case {2,3} % interval fiducial/ fixed intereval fiducial
                v = events.value(1,p,1);
                v2 = events.value(1,p,2);
                events.handle(1,p) = patch('parent',events.axes,'Xdata',[v v v2 v2],'Ydata',[ywin ywin([2 1])],'FaceColor',colorlist{events.type(p)},'hittest','off','FaceAlpha', 0.4,'linewidth',events.linewidth{events.type(p)},'linestyle',events.linestyle{events.type(p)});
        end
    end
    AUTOPROCESSING.EVENTS{beatNumber}{1} = events;           

    if myScriptData.DISPLAYTYPEA == 1, continue; end

    %%%% GROUP FIDUCIALS

    events = AUTOPROCESSING.EVENTS{beatNumber}{2};
    if ~isempty(events.handle), index = find(ishandle(events.handle(:)) & (events.handle(:) ~= 0)); delete(events.handle(index)); end
    events.handle = [];
    if AUTOPROCESSING.SELFIDS == 2, colorlist = events.colorlist; else colorlist = events.colorlistgray; end

    numchannels = size(AUTOPROCESSING.SIGNAL,1);
    chend = numchannels - max([floor(ywin(1)) 0]);
    chstart = numchannels - min([ceil(ywin(2)) numchannels])+1;

    index = chstart:chend;

    for q=1:max(AUTOPROCESSING.LEADGROUP)
        nindex = index(AUTOPROCESSING.LEADGROUP(index)==q);
        if isempty(nindex), continue; end
        ydata = numchannels-[min(nindex)-1 max(nindex)];


        for p=1:size(events.value,2)
            switch events.typelist(events.type(p))
                case 1 % normal fiducial
                    v = events.value(q,p,1);
                    events.handle(q,p) = line('parent',events.axes,'Xdata',[v v],'Ydata',ydata,'Color',colorlist{events.type(p)},'hittest','off','linewidth',events.linewidth{events.type(p)},'linestyle',events.linestyle{events.type(p)});
                case {2,3} % interval fiducial/ fixed intereval fiducial
                    v = events.value(q,p,1);
                    v2 = events.value(q,p,2);
                    events.handle(q,p) = patch('parent',events.axes,'Xdata',[v v v2 v2],'Ydata',[ydata ydata([2 1])],'FaceColor',colorlist{events.type(p)},'hittest','off','FaceAlpha', 0.4,'linewidth',events.linewidth{events.type(p)},'linestyle',events.linestyle{events.type(p)});
            end
        end
    end
    AUTOPROCESSING.EVENTS{beatNumber}{2} = events;   

    if myScriptData.DISPLAYTYPEA == 2, continue; end

    %%%% LOCAL FIDUCIALS

    events = AUTOPROCESSING.EVENTS{beatNumber}{3};

    %%%% delete all current handles and set events.handles=[]
     if ~isempty(events.handle)
         index = find(ishandle(events.handle(:)) & (events.handle(:) ~= 0));
         delete(events.handle(index))
     end
    events.handle = [];


    if AUTOPROCESSING.SELFIDS == 3, colorlist = events.colorlist; else colorlist = events.colorlistgray; end


    %%%% index is eg [3 4 5 8 9 10], if those are the leads (in global frame) currently
    %%%% displayed (this changes with yslider!, note 5 8 !

    index = AUTOPROCESSING.LEAD(chstart:chend);
    for q=index     % for each of the 5-7 channels, that one can see in axes
        for idx=find(q==AUTOPROCESSING.LEAD)
            ydata = numchannels-[idx-1 idx];   % y-value, from where to where each local fid is plottet, eg [15, 16]  
            for p=1:size(events.value,2)   % for each fid of that channel
                switch events.typelist(events.type(p))
                    case 1 % normal fiducial
                        v = events.value(q,p,1);
                       events.handle(q,p) = line('parent',events.axes,'Xdata',[v v],'Ydata',ydata,'Color',colorlist{events.type(p)},'hittest','off','linewidth',events.linewidth{events.type(p)},'linestyle',events.linestyle{events.type(p)});
                    case {2,3} % interval fiducial/ fixed intereval fiducial
                        v = events.value(q,p,1);
                        v2 = events.value(q,p,2);
                        events.handle(q,p) = patch('parent',events.axes,'Xdata',[v v v2 v2],'Ydata',[ydata ydata([2 1])],'FaceColor',colorlist{events.type(p)},'hittest','off','FaceAlpha', 0.4,'linewidth',events.linewidth{events.type(p)},'linestyle',events.linestyle{events.type(p)});
                end
            end
        end
    end
    AUTOPROCESSING.EVENTS{beatNumber}{3} = events;
    
end










function findFaultyBeats(cbobj)
% callback function to 'find faulty beats' push button
global AUTOPROCESSING

%%%% first, find faulty beats based on current treshold variance %%%%%
getFaultyBeats

%%%% now update display accordingly
initDisplayButtons(cbobj.Parent)

%%%% if there are no faulty beats, zoom out, else simply update display
numFaultyBeats = length(AUTOPROCESSING.faultyBeatIndeces);
if numFaultyBeats == 0
    goBack2Overview
else
    UpdateDisplay
end



function zoomIntoBeat(cbobj)
% callback of a view of the faulty beats button
global AUTOPROCESSING myScriptData


%%%% return if there are no faulty beats to zoom into..
numFaultyBeats = length(AUTOPROCESSING.faultyBeatIndeces);
if numFaultyBeats == 0
    return
end

%%%% check if a beat has been selected before
if ~isfield(AUTOPROCESSING, 'faultyBeatIndex')
    AUTOPROCESSING.faultyBeatIndex = 1; % if nothing selected, select first beat
end

%%%% determine the new faultyBeatIndex depending on what called this function
switch cbobj.Tag
    case 'PREVIOUSBEAT'  % previous faulty beat pushbutton
        if AUTOPROCESSING.faultyBeatIndex < 2
            faultyBeatIndex = 1;
        else
            faultyBeatIndex = AUTOPROCESSING.faultyBeatIndex -1;
        end
    case 'NEXTBEAT'   % next faulty beat pushbutton
        if AUTOPROCESSING.faultyBeatIndex >= numFaultyBeats
            faultyBeatIndex = numFaultyBeats;
        else
            faultyBeatIndex = AUTOPROCESSING.faultyBeatIndex + 1;
        end
    case 'SELFAULTYBEAT'   % beat selection popup menu
        faultyBeatIndex = cbobj.Value;
end
AUTOPROCESSING.faultyBeatIndex = faultyBeatIndex;

%%%% set the popup menu to the current beat2beInspected
selBeatPopupObj = findobj(allchild(cbobj.Parent),'Tag','SELFAULTYBEAT');
selBeatPopupObj.Value = faultyBeatIndex;


%%%% set the plot window limits to zoom int beat2beInspected
beat2beInspected = AUTOPROCESSING.faultyBeatIndeces(faultyBeatIndex);
beatStart = AUTOPROCESSING.beats{beat2beInspected}(1)/myScriptData.SAMPLEFREQ;
beatEnd = AUTOPROCESSING.beats{beat2beInspected}(2)/myScriptData.SAMPLEFREQ;
beatLenght = beatEnd-beatStart;
AUTOPROCESSING.XWIN =[beatStart-0.2*beatLenght, beatEnd+0.2*beatLenght];


UpdateDisplay

function goBack2Overview(~)
% callback to Go Back to Overview push button
global AUTOPROCESSING myScriptData
AUTOPROCESSING.XWIN = [median([0 AUTOPROCESSING.XLIM]) median([3000/myScriptData.SAMPLEFREQ AUTOPROCESSING.XLIM])];
UpdateDisplay



function potvals=temporalFilter(potvals)
% TODO, this should not be needed here
A = 1;
B = [0.03266412226059 0.06320942361376 0.09378788647083 0.10617422096837 0.09378788647083 0.06320942361376 0.03266412226059];
D = potvals';
D = filter(B,A,D);
D(1:(max(length(A),length(B))-1),:) = ones(max(length(A),length(B))-1,1)*D(max(length(A),length(B)),:);
potvals = D';

function signal = preprocessPotvals(potvals)
% do temporal filter and RMS, to get a signal to work with

%%%% temporal filter
A = 1;
B = [0.03266412226059 0.06320942361376 0.09378788647083 0.10617422096837 0.09378788647083 0.06320942361376 0.03266412226059];
D = potvals';
D = filter(B,A,D);
D(1:(max(length(A),length(B))-1),:) = ones(max(length(A),length(B))-1,1)*D(max(length(A),length(B)),:);
potvals = D';

%%%% do RMS
signal=rms(potvals,1);
signal=signal-min(signal);


%%% scaling
k = max(abs(signal),[],2);
[m,~] = size(signal);
k(k==0) = 1;
s = sparse(1:m,1:m,1./k,m,m);
signal = full(s*signal);

%%%%%%% callback functions %%%%%%%%%%%%%%%%%%%%%

function Navigation(handle,mode)
%callback to all navigation buttons (including apply)
global myScriptData
disp('navigating')
switch mode
case {'prev','next','stop'}
    myScriptData.NAVIGATION = mode;
    set(handle,'DeleteFcn','');
    delete(handle);
case {'apply'}
    %TODO.. what to do when applied is pressed...
    myScriptData.NAVIGATION = 'apply';
    disp('applying')
    EventsToFids
    set(handle,'DeleteFcn','');
    delete(handle);
otherwise
    error('unknown navigation command');
end

function scrollFcn(handle, eventData)
%callback for scrolling
diff=(-1)*eventData.VerticalScrollCount*0.05;

yslider=findobj(allchild(handle),'tag','SLIDERY');
value=yslider.Value;

value=value+diff;

if value > 1, value=1; end
if value < 0, value=0; end

yslider.Value=value;

UpdateSlider(yslider)



function Zoom(handle)
global AUTOPROCESSING;
value = get(handle,'value');
parent = get(handle,'parent');
switch value
    case 0
        set(parent,'WindowButtonDownFcn','plotAutoProcFids(''ButtonDown'',gcbf)',...
           'WindowButtonMotionFcn','plotAutoProcFids(''ButtonMotion'',gcbf)',...
           'WindowButtonUpFcn','plotAutoProcFids(''ButtonUp'',gcbf)',...
           'pointer','arrow');
        set(handle,'string','Zoom OFF');
        AUTOPROCESSING.ZOOM = 0;
    case 1
        set(parent,'WindowButtonDownFcn','plotAutoProcFids(''ZoomDown'',gcbf)',...
           'WindowButtonMotionFcn','plotAutoProcFids(''ZoomMotion'',gcbf)',...
           'WindowButtonUpFcn','plotAutoProcFids(''ZoomUp'',gcbf)',...
           'pointer','crosshair');
        set(handle,'string','Zoom ON');
        AUTOPROCESSING.ZOOM = 1;
end


function ZoomDown(handle)

global AUTOPROCESSING    
seltype = get(gcbf,'SelectionType');
if ~strcmp(seltype,'alt')
    pos = get(AUTOPROCESSING.AXES,'CurrentPoint');
    P1 = pos(1,1:2); P2 = P1;
    AUTOPROCESSING.P1 = P1;
    AUTOPROCESSING.P2 = P2;
    X = [ P1(1) P2(1) P2(1) P1(1) P1(1) ]; Y = [ P1(2) P1(2) P2(2) P2(2) P1(2) ];
    AUTOPROCESSING.ZOOMBOX = line('parent',AUTOPROCESSING.AXES,'XData',X,'YData',Y,'Color','k','HitTest','Off');
    drawnow;
else
    xlim = AUTOPROCESSING.XLIM; ylim = AUTOPROCESSING.YLIM;
    xwin = AUTOPROCESSING.XWIN; ywin = AUTOPROCESSING.YWIN;
    xsize = max([2*(xwin(2)-xwin(1)) 1]);
    AUTOPROCESSING.XWIN = [ median([xlim xwin(1)-xsize/4]) median([xlim xwin(2)+xsize/4])];
    ysize = max([2*(ywin(2)-ywin(1)) 1]);
    AUTOPROCESSING.YWIN = [ median([ylim ywin(1)-ysize/4]) median([ylim ywin(2)+ysize/4])];
    UpdateDisplay;
end

    
function ZoomMotion(handle)
global AUTOPROCESSING    
if ishandle(AUTOPROCESSING.ZOOMBOX)
    point = get(AUTOPROCESSING.AXES,'CurrentPoint');
    P2(1) = median([AUTOPROCESSING.XLIM point(1,1)]); P2(2) = median([AUTOPROCESSING.YLIM point(1,2)]);
    AUTOPROCESSING.P2 = P2;
    P1 = AUTOPROCESSING.P1;
    X = [ P1(1) P2(1) P2(1) P1(1) P1(1) ]; Y = [ P1(2) P1(2) P2(2) P2(2) P1(2) ];
    set(AUTOPROCESSING.ZOOMBOX,'XData',X,'YData',Y);
    drawnow;
end

    
function ZoomUp(handle)  
global AUTOPROCESSING;    
if ishandle(AUTOPROCESSING.ZOOMBOX)
    point = get(AUTOPROCESSING.AXES,'CurrentPoint');
    P2(1) = median([AUTOPROCESSING.XLIM point(1,1)]); P2(2) = median([AUTOPROCESSING.YLIM point(1,2)]);
    AUTOPROCESSING.P2 = P2; P1 = AUTOPROCESSING.P1;
    if (P1(1) ~= P2(1)) && (P1(2) ~= P2(2))
        AUTOPROCESSING.XWIN = sort([P1(1) P2(1)]);
        AUTOPROCESSING.YWIN = sort([P1(2) P2(2)]);
    end
    delete(AUTOPROCESSING.ZOOMBOX);
    UpdateDisplay;
end


function ButtonDown(handle)
%callback for mouse click   
% - checks if mouseclick is in winy/winx
% - checks if no right click:
%        - if yes: events=FindClosestEvents(events,t)
%           - if event.sel(1)>1 (if erste oder zweite linie gew�hlt):
%               - SetClosestEvent
%        - else: AddEvent
% - if right click: events=AddEvent(events,t)
% - update the .EVENTS
global AUTOPROCESSING myScriptData

seltype = get(gcbf,'SelectionType');   % double click, right click etc
if strcmp(seltype,'alt'), return, end % if "right click", return
point = get(AUTOPROCESSING.AXES,'CurrentPoint');
t = point(1,1); y = point(1,2);

xwin = AUTOPROCESSING.XWIN;
ywin = AUTOPROCESSING.YWIN;
if (t>xwin(1))&&(t<xwin(2))&&(y>ywin(1))&&(y<ywin(2))     % if mouseclick within axes
    %%%% get the right event to modify
    AUTOPROCESSING.CurrentEventIdx=[];
    for beatNumber =1:length(AUTOPROCESSING.beats)
        if t > AUTOPROCESSING.beats{beatNumber}(1)/myScriptData.SAMPLEFREQ && t < AUTOPROCESSING.beats{beatNumber}(2)/myScriptData.SAMPLEFREQ  % if mouseclick within beat
            AUTOPROCESSING.CurrentEventIdx = beatNumber; % remember that beat
            break
        end
    end
    
    if isempty(AUTOPROCESSING.CurrentEventIdx), return, end % if click not within a beat, return..
    
    %%%% get event of beat, mark the closest fid in it, then update it and save it
    events = AUTOPROCESSING.EVENTS{AUTOPROCESSING.CurrentEventIdx}{AUTOPROCESSING.SELFIDS}; %local, group, or global fids of the beat where click occured
    events = FindClosestEvent(events,t,y);       % update sel, sel1, sel2
    
    %%%% check if there is a red line that might have to be removed in that beat
    if any(AUTOPROCESSING.faultyBeatIndeces == AUTOPROCESSING.CurrentEventIdx)
        %%%% so there is a red line.. see if it belongs to the fid that was selected. in that case remove it
        y_val = events.value(events.sel3,events.sel, events.sel2)*myScriptData.SAMPLEFREQ; % y-value of selected fid
        faultyBeatIndex = find(AUTOPROCESSING.faultyBeatIndeces == AUTOPROCESSING.CurrentEventIdx);   
        dif = abs(AUTOPROCESSING.faultyBeatValues{faultyBeatIndex} - y_val);
        faultyFidIndex = find(dif < 0.99 ); % find index where distance of red line to selected fid is cloes enough
        
        if ~isempty(faultyFidIndex) % if red line belongts to user-selected fid
            % set Variance of changed fid to 0, since this variance means nothing anymore (because the user changed that fid!)
            fidType = AUTOPROCESSING.faultyBeatInfo{faultyBeatIndex}(faultyFidIndex);
            idx=find( [AUTOPROCESSING.allFids{AUTOPROCESSING.CurrentEventIdx}.type] == fidType );
            AUTOPROCESSING.allFids{AUTOPROCESSING.CurrentEventIdx}(idx(1)).variance = 0;
            
            % delete line obj and all other entries that that fid was bad
            delete(AUTOPROCESSING.faultyBeatLineHandles{faultyBeatIndex}(faultyFidIndex))
            AUTOPROCESSING.faultyBeatLineHandles{faultyBeatIndex}(faultyFidIndex) = [];
            AUTOPROCESSING.faultyBeatValues{faultyBeatIndex}(faultyFidIndex) = [];
            AUTOPROCESSING.faultyBeatInfo{faultyBeatIndex}(faultyFidIndex) = [];


        end
    end
    
    %%%% set closest event and save it
    events = SetClosestEvent(events,t,y);
    AUTOPROCESSING.EVENTS{AUTOPROCESSING.CurrentEventIdx}{AUTOPROCESSING.SELFIDS} = events;   % save the event after it has been modified
end


function ButtonMotion(handle)
% as long as something is selected (sel>0), continuously setClosestEvent.    
global AUTOPROCESSING

if ~isfield(AUTOPROCESSING,'CurrentEventIdx'), return, end
if isempty(AUTOPROCESSING.CurrentEventIdx), return, end  % if nothing selected currently, return

events = AUTOPROCESSING.EVENTS{AUTOPROCESSING.CurrentEventIdx}{AUTOPROCESSING.SELFIDS};  
if events.sel(1) > 0
    point = get(AUTOPROCESSING.AXES,'CurrentPoint');
    t = median([AUTOPROCESSING.XLIM point(1,1)]);
    y = median([AUTOPROCESSING.YLIM point(1,2)]);
    AUTOPROCESSING.EVENTS{AUTOPROCESSING.CurrentEventIdx}{AUTOPROCESSING.SELFIDS} = SetClosestEvent(events,t,y);
end

function ButtonUp(handle)
% - get the current event
% - if some event is selected (sel>0): SetClosestEvent
% - set sel=sel2=sel3=0
% - do some Activation/Recovery stuff (TODO: remove this?)

global AUTOPROCESSING  myScriptData;
if isempty(AUTOPROCESSING.CurrentEventIdx), return, end % if nothing selected, return..   

events = AUTOPROCESSING.EVENTS{AUTOPROCESSING.CurrentEventIdx}{AUTOPROCESSING.SELFIDS};        
if events.sel(1) > 0
    point = get(AUTOPROCESSING.AXES,'CurrentPoint');
    t = median([AUTOPROCESSING.XLIM point(1,1)]);
    y = median([AUTOPROCESSING.YLIM point(1,2)]);
    events = SetClosestEvent(events,t,y); 
%    sel = events.sel;

    %%%% deselect everything in event, so no fid is selected after button up
    events.sel = 0;
    events.sel2 = 0;
    events.sel3 = 0;
    
    
    %%%% save the modified event
    AUTOPROCESSING.EVENTS{AUTOPROCESSING.CurrentEventIdx}{AUTOPROCESSING.SELFIDS} = events;
    
    %%%% deselect event (beat)
    AUTOPROCESSING.CurrentEventIdx=[];


%     %%%% do activation/recovery if FIDSAUTOACT is on
%     if (events.type(sel) == 2) && (myScriptData.FIDSAUTOACT == 1), DetectActivation(handle); end
%     if (events.type(sel) == 3) && (myScriptData.FIDSAUTOREC == 1), DetectRecovery(handle); end
end



function UpdateSlider(handle,~)
%callback to slider
global AUTOPROCESSING
tag = get(handle,'tag');
value = get(handle,'value');
switch tag
    case 'SLIDERX'
        xwin = AUTOPROCESSING.XWIN;
        xlim = AUTOPROCESSING.XLIM;
        winlen = xwin(2)-xwin(1);
        limlen = xlim(2)-xlim(1);
        xwin(1) = median([xlim value*(limlen-winlen)+xlim(1)]);
        xwin(2) = median([xlim xwin(1)+winlen]);
        AUTOPROCESSING.XWIN = xwin;
   case 'SLIDERY'
        ywin = AUTOPROCESSING.YWIN;
        ylim = AUTOPROCESSING.YLIM;
        winlen = ywin(2)-ywin(1);
        limlen = ylim(2)-ylim(1);
        ywin(1) = median([ylim value*(limlen-winlen)+ylim(1)]);
        ywin(2) = median([ylim ywin(1)+winlen]);
        AUTOPROCESSING.YWIN = ywin;     
end

UpdateDisplay;

function DisplayButton(cbobj)
%callback function to all the buttons
global myScriptData AUTOPROCESSING


switch cbobj.Tag
    case {'DISPLAYTYPEA','DISPLAYOFFSETA','DISPLAYSCALINGA','DISPLAYGROUPA'}  % in case display needs to be updated.. any of buttons regarding display
        myScriptData.(cbobj.Tag)=cbobj.Value;
        setupDisplay(cbobj.Parent)
        UpdateDisplay
    case {'TRESHOLD_VAR'}     % in case of str2double and AUTOPROCESSING needs update
        newNumber = str2double(cbobj.String);        
        if isnan(newNumber)
            cbobj.String = num2str(AUTOPROCESSING.(cbobj.Tag));
            return
        end
        AUTOPROCESSING.(cbobj.Tag)=newNumber;
        
    otherwise
        myScriptData.(cbobj.Tag)=cbobj.Value;
        UpdateDisplay
end


function SetFids(handle)
%callback function to the two buttons ('Global Fids', 'local Fids')

global AUTOPROCESSING;
window = get(handle,'parent');
tag = get(handle,'tag');
switch tag
    case 'FIDSGLOBAL'
        AUTOPROCESSING.SELFIDS = 1;
        set(findobj(allchild(window),'tag','FIDSGLOBAL'),'value',1);
        set(findobj(allchild(window),'tag','FIDSLOCAL'),'value',0);          
    case 'FIDSLOCAL'
        AUTOPROCESSING.SELFIDS = 3;
        set(findobj(allchild(window),'tag','FIDSGLOBAL'),'value',0);
        set(findobj(allchild(window),'tag','FIDSLOCAL'),'value',1);
end
DisplayFiducials;


function KeyPress(fig)
global AUTOPROCESSING
key = real(fig.CurrentCharacter);

if isempty(key), return; end
if ~isnumeric(key), return; end

switch key(1) 
    case 32    % spacebar
        Navigation(gcbf,'apply');
    case {81,113}    % q/Q
        Navigation(gcbf,'prev');
    case {87,119}    % w
        Navigation(gcbf,'stop');
    case {69,101}    % e
        Navigation(gcbf,'next');
end


%%%%%%% util functions %%%%%%%%%%%%%%%%%%%%%%%
%TODO I think I dont need this
function fids=removeUnnecFids(fids,wantedFids)
toBeRemoved=[];
for p=1:length(fids)
    if ~ismember(fids(p).type, wantedFids)
        toBeRemoved=[toBeRemoved p];
    end
end
fids(toBeRemoved)=[];


function InitFiducials(fig)
% sets up .EVENTS
% sets up DefaultEvent
% calls FidsToEvents


global myScriptData TS AUTOPROCESSING;


% for all fiducial types
events.dt = myScriptData.BASELINEWIDTH/myScriptData.SAMPLEFREQ;
events.value = [];
events.type = [];
events.handle = [];
events.axes = findobj(allchild(fig),'tag','AXES');
events.colorlist = {[1 0.7 0.7],[0.7 1 0.7],[0.7 0.7 1],[0.5 0 0],[0 0.5 0],[0 0 0.5],[1 0 1],[1 1 0],[0 1 1],  [1 0.5 0],[1 0.5 0]};
events.colorlistgray = {[0.8 0.8 0.8],[0.8 0.8 0.8],[0.8 0.8 0.8],[0.8 0.8 0.8],[0.8 0.8 0.8],[0.8 0.8 0.8],[0.8 0.8 0.8],[0.8 0.8 0.8],[0.8 0.8 0.8],   [0.8 0.8 0.8],[0.8 0.8 0.8]};
events.typelist = [2 2 2 1 1 3 1 1 1 1 2];
events.linestyle = {'-','-','-','-.','-.','-','-','-','-','-','-'};
events.linewidth = {1,1,1,2,2,1,2,2,2,2,2,1};
events.num = [1 2 3 4 5 7 8 9 10 11];

AUTOPROCESSING.fidslist = {'P-wave','QRS-complex','T-wave','QRS-peak','T-peak','Activation','Recovery','Reference','X-Peak','X-Wave'};     

AUTOPROCESSING.NUMTYPES = length(AUTOPROCESSING.fidslist);
AUTOPROCESSING.SELFIDS = 1;
set(findobj(allchild(fig),'tag','FIDSGLOBAL'),'value',1);
set(findobj(allchild(fig),'tag','FIDSLOCAL'),'value',0);


events.sel = 0;
events.sel2 = 0;
events.sel3 = 0;

events.maxn = 1;
events.class = 1; AUTOPROCESSING.DEFAULT_EVENTS{1} = events;  % GLOBAL EVENTS
events.maxn = length(myScriptData.GROUPLEADS{myScriptData.CURRENTRUNGROUP});
events.class = 2; AUTOPROCESSING.DEFAULT_EVENTS{2} = events;  % GROUP EVENTS
events.maxn = size(TS{myScriptData.CURRENTTS}.potvals,1);
events.class = 3; AUTOPROCESSING.DEFAULT_EVENTS{3} = events;  % LOCAL EVENTS

FidsToEvents;


function FidsToEvents
%puts .allFids into .EVENTS

global TS myScriptData AUTOPROCESSING;

samplefreq = myScriptData.SAMPLEFREQ;
isamplefreq = 1/samplefreq;

for beatNumber=1:length(AUTOPROCESSING.allFids)  %for each beat
    AUTOPROCESSING.EVENTS{beatNumber}=AUTOPROCESSING.DEFAULT_EVENTS;
    fids=AUTOPROCESSING.allFids{beatNumber};
    
    %%%% find the start_value and the end_value of a wave
    %this takes advantage of the fact, that end of wave imediatly follows beginning of waves in fids
    
    fidsIndex=1;
    while fidsIndex <=length(fids)
         switch fids(fidsIndex).type
            case 0
                mtype = 1;    
                start_value = fids(fidsIndex).value*isamplefreq;
                end_value= fids(fidsIndex+1).value*isamplefreq;
                fidsIndex=fidsIndex+1; % if its a wave, skip next entry (the end of wave)
            case 2
                mtype = 2;
                start_value = fids(fidsIndex).value*isamplefreq;
                end_value= fids(fidsIndex+1).value*isamplefreq;
                fidsIndex=fidsIndex+1;
            case 5
                mtype = 3;
                start_value = fids(fidsIndex).value*isamplefreq;
                end_value= fids(fidsIndex+1).value*isamplefreq;
                fidsIndex=fidsIndex+1;      
            case 3
                mtype = 4; start_value = fids(fidsIndex).value*isamplefreq; end_value = start_value;
            case 6
                mtype = 5; start_value = fids(fidsIndex).value*isamplefreq; end_value = start_value;
            case 16
                mtype = 6; start_value = fids(fidsIndex).value*isamplefreq; end_value = start_value+myScriptData.BASELINEWIDTH/samplefreq;
            case 10
                mtype = 7; start_value = fids(fidsIndex).value*isamplefreq; end_value = start_value;
            case 13
                mtype = 8; start_value = fids(fidsIndex).value*isamplefreq; end_value = start_value;
            case 14
                mtype = 9; start_value = fids(fidsIndex).value*isamplefreq; end_value = start_value;
            case 26     % X-Wave
                mtype = 11;
                start_value = fids(fidsIndex).value*isamplefreq;
                end_value= fids(fidsIndex+1).value*isamplefreq;
                fidsIndex=fidsIndex+1;
            case 25   %X-Peak
                mtype = 10; start_value = fids(fidsIndex).value*isamplefreq; end_value = start_value;
            otherwise
                continue;
         end
        fidsIndex=fidsIndex+1;
        
        %start_value is now first value(s) of wave, end_value is last value(s) of wave. if the fiducial is a peak, they are both the same.
      	%mtype correstponds to: fidslist = {'P-wave','QRS-complex','T-wave','QRS-peak','T-peak','Baseline','Activation','Recovery','Reference','Fbase'};
        % eg. mtype=3 means it's a T-wave, because fidslist{3}='T-Wave'
        
        %%%% now check if it is global or local fid and put the values of start_value/end_value in events.value
        numLeadsToAutoprocess = length(AUTOPROCESSING.leadsToAutoprocess);
        if (length(start_value) == numLeadsToAutoprocess)&&(length(end_value) == numLeadsToAutoprocess) % if individual value for each lead
            AUTOPROCESSING.EVENTS{beatNumber}{3}.value(AUTOPROCESSING.leadsToAutoprocess,end+1,1) = start_value;
            AUTOPROCESSING.EVENTS{beatNumber}{3}.value(AUTOPROCESSING.leadsToAutoprocess,end,2) = end_value;
            AUTOPROCESSING.EVENTS{beatNumber}{3}.type(end+1) = mtype;
        elseif (length(start_value) ==1)&&(length(end_value) == 1) % if global fiducials
            AUTOPROCESSING.EVENTS{beatNumber}{1}.value(:,end+1,1) = start_value;
            AUTOPROCESSING.EVENTS{beatNumber}{1}.value(:,end,2) = end_value;
            AUTOPROCESSING.EVENTS{beatNumber}{1}.type(end+1) = mtype; 
        end
    end
end

function EventsToFids
% put the events back into allFids
disp('E2F')
global myScriptData AUTOPROCESSING

samplefreq = myScriptData.SAMPLEFREQ;
isamplefreq = (1/samplefreq);

for beatNumber=1:length(AUTOPROCESSING.allFids)  %for each beat
    fids = [];

    %%%% store the fids Data from global,local,group fids from event.value in val1,val2,mtype 
    val1 = {};
    val2 = {};
    mtype = {};  
    % first the global fids
    for p=1:length(AUTOPROCESSING.EVENTS{beatNumber}{1}.type)
        val1{end+1} = round(AUTOPROCESSING.EVENTS{beatNumber}{1}.value(1,p,1)*samplefreq);
        val2{end+1} = round(AUTOPROCESSING.EVENTS{beatNumber}{1}.value(1,p,2)*samplefreq);
        mtype{end+1} = AUTOPROCESSING.EVENTS{beatNumber}{1}.type(p);
    end
    % EXPLANATION OF val1, val2, mtype
    % val1{1:NumGlobalFids}=firstValueOfGlobalFids,
    % val2 analogous, but second value of fid.    mtype same, but with fiducial event.type instead of values.
    
    %%%% for each added fiducial (of all types): add it to fids
    for p=1:length(val1)
        v1 = min([val1{p} val2{p}],[],2);
        v2 = max([val1{p} val2{p}],[],2);
        % add fids.type, fids.value,  translate from
        % event.type to fids.type
        switch mtype{p}
            case 1
                fids(end+1).value = v1;
                fids(end).type = 0;
                fids(end+1).value = v2;
                fids(end).type = 1;
            case 2
                fids(end+1).value = v1;
                fids(end).type = 2;
                fids(end+1).value = v2;
                fids(end).type = 4;
            case 3
                fids(end+1).value = v1;
                fids(end).type = 5;
                fids(end+1).value = v2;
                fids(end).type = 7;
            case 4
                fids(end+1).value = v1;
                fids(end).type = 3;
            case 5
                fids(end+1).value = v1;
                fids(end).type = 6;
            case 6
                fids(end+1).value = v1;
                fids(end).type = 16;
            case 7
                fids(end+1).value = v1;
                fids(end).type = 10;
            case 8
                fids(end+1).value = v1;
                fids(end).type = 13;
            case 9
                fids(end+1).value = v1;
                fids(end).type = 14;
            case 10 % X-Peak
                fids(end+1).value = v1;
                fids(end).type = 25;
            case 11 % X-Wave
                fids(end+1).value = v1;
                fids(end).type = 26;
                fids(end+1).value = v2;
                fids(end).type = 27;
        end
    end
    
    %%%% save the fids in allFids
    AUTOPROCESSING.allFids{beatNumber} = fids;
end
    
    
    
    
    
function getFaultyBeats
% determine the beats, where autoprocessing didn't quite work ( eg those with very high variance)
% fill AUTOPROCESSING.faultyBeatInfo and AUTOPROCESSING.faultyBeatIndeces with info

global AUTOPROCESSING

%%%% if not set yet, set default for treshold variance
if ~isfield(AUTOPROCESSING, 'TRESHOLD_VAR')
    AUTOPROCESSING.TRESHOLD_VAR = 50;
end


%%%% set up variables
treshold_variance = AUTOPROCESSING.TRESHOLD_VAR;
faultyBeatIndeces =[]; % the indeces of faulty beats
faultyBeatInfo = {};    % which fiducials in the beat are bad?
faultyBeatValues = {};
numBeats = length(AUTOPROCESSING.beats);

%%%% loop through beats and find faulty ones
for beatNumber = 1:numBeats
    types = [AUTOPROCESSING.allFids{beatNumber}.type];
    variances =[AUTOPROCESSING.allFids{beatNumber}.variance];
    
    faultyIndeces = find(variances > treshold_variance);
    
    faultyFids = types(faultyIndeces); % get fids with to high variance
    
    if isempty(faultyFids) % if all fids of that beat are fine
        continue
    else
        faultyBeatIndeces(end+1) = beatNumber;
        faultyBeatInfo{end+1} = faultyFids;
        
        %%%% get the faultyValues of that faulty beat
        faultyIndeces = faultyIndeces + 5;  % now faultyIndeces are indeces of global bad fiducials
        faultyValues = [AUTOPROCESSING.allFids{beatNumber}(faultyIndeces).value];
        faultyBeatValues{end+1}=faultyValues;
    end
    
end


%%%% save stuff in AUTOPROCESSING
AUTOPROCESSING.faultyBeatInfo = faultyBeatInfo;
AUTOPROCESSING.faultyBeatIndeces = faultyBeatIndeces;
AUTOPROCESSING.faultyBeatValues = faultyBeatValues;

    
function events = SetClosestEvent(events,t,~)
% - sets/redraws the patch identified by sel,sel1,sel3 (which are set by FindClosestEvent)
%   at the new value t 
% - updates the events. values corresponding to that patch
% if sel==0 it returns imediatly


s = events.sel;
s2 = events.sel2;
s3 = events.sel3;

switch events.typelist(events.type(s))
   case 1
        for w=s3
            if (events.handle(w,s) > 0)&&(ishandle(events.handle(w,s))), set(events.handle(w,s),'XData',[t t]); end
            events.value(w,s,[1 2]) = [t t];
        end
        %drawnow;
    case 2
        for w=s3
            events.value(w,s,s2) = t;
            t1 = events.value(w,s,1);
            t2 = events.value(w,s,2);
            if (events.handle(w,s) > 0)&&(ishandle(events.handle(w,s))), set(events.handle(w,s),'XData',[t1 t1 t2 t2]); end
        end
        %drawnow;  
    case 3
        for w=s3
            dt = diff(events.value(w,s,[s2 (3-s2)]));
            events.value(w,s,s2) = t; events.value(w,s,(3-s2)) = t+dt;
            t1 = events.value(w,s,1);
            t2 = events.value(w,s,2);
            if (events.handle(w,s) > 0)&&(ishandle(events.handle(w,s))),  set(events.handle(w,s),'XData',[t1 t1 t2 t2]); end
        end
        %drawnow;  
end

function events = FindClosestEvent(events,t,y)
% returns events untouched, exept that sel1, sel2 sel3 are changed:
% sel=1 => erster balken am n�chsten zu input t,  sel=2  =>2. balken am n�chstn  
% sel2=1  => erste Strich von balken am n�chsten,  sel2=2  => zweiter strich n�her
% alle sel sind 0, falls isempty(value)
%sel3 ist bei global gleich 1, ansonsten ist sel3 glaub lead..
global AUTOPROCESSING

if isempty(events.value)                                       %sels are all 0 if first time
    events.sel = 0;
    events.sel2 = 0;
    events.sel3 = 0;
    return
end

value=events.value;


switch events.class
    case 1
        tt = abs(permute(value(1,:,:),[3 2 1])-t);   % tt=[ AbstZu1StrOf1Line, AbstZu1StrOf2Line; AbstZu2StrOf1Line, AbstZu2StrOf2Line], abstand von mouseclick (2x2x1) matrix)
        [events.sel2,events.sel] = find(tt == min(tt(:)));   
        events.sel = events.sel(1);         % sel=1 => erster balken am n�chsten,  sel=2  =>2. balken am n�chstn                 
        events.sel2 = events.sel2(1);       % sel2=1  => erste Strich von balken am n�chsten,  sel2=2  => zweiter strich n�her
        events.sel3 = 1;

    case 2
        numchannels = size(AUTOPROCESSING.SIGNAL,1);
        ch = median([ 1 numchannels-floor(y)  numchannels]);
        group = AUTOPROCESSING.GROUP(ch);
        tt = abs(permute(value(group,:,:),[3 2 1])-t);
        [events.sel2,events.sel] = find(tt == min(tt(:)));
        events.sel = events.sel(1);
        events.sel2 = events.sel2(1);
        events.sel3 = group;
    case 3
         numchannels = size(AUTOPROCESSING.SIGNAL,1);
        ch = median([ 1 numchannels-floor(y)  numchannels]);
        lead = AUTOPROCESSING.LEAD(ch);
        tt = abs(permute(value(lead,:,:),[3 2 1])-t);
        [events.sel2,events.sel] = find(tt == min(tt(:)));
        events.sel = events.sel(1);
        events.sel2 = events.sel2(1);
        events.sel3 = lead;
end


% events.latestEvent=[events.sel, events.sel2, events.sel3];  % needed in keypress fcn


