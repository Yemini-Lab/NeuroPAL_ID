function hh=ticklabelinside(h,ax,cornerflag)
%TICKLABELINSIDE moves tick labels to the inside of the plot axis
%   HH=TICKLABELINSIDE(H,AX,CORNERFLAG) is the calling form.
%   HH contains handles to the text objects created.
%   H is the handle to the figure or axis of interest (default is GCF).
%   AX is 'x' 'y' or 'xy' (default) to indicate which axis labels should be moved in.
%   CORNERFLAG is 1 to print labels at the corners, 0 to skip them for clarity (default)
%
%   Run this file after all plotting is complete - labels do not update
%      with axis zooming or panning.
%
%   NOTE: to move axis ticks out you can call SET(gca,'tickdir','out')
%   NOTE: this doesn't work with log plots.
%
%   Example 1: A smiley face, with a variety of options.
%      figure, x=0:10;
%      h(1)=subplot(221); rectangle('position',[-1e7 -1e7 2e7 2e7],'curvature',[1 1],'linewidth',2,'edgecolor','b'), title('Regular old plot'), xlabel('outside'), ylabel('outside')
%      h(2)=subplot(222); rectangle('position',[-1e7 -1e7 2e7 2e7],'curvature',[1 1],'linewidth',2,'edgecolor','b'), h1=ticklabelinside(h(2)); title('ticklabelinside(h(2))'), xlabel('inside'), ylabel('inside')
%      h(3)=subplot(223); plot(-x,x.^2,'r.-',-x,.5*x.^2+50,'r.-'), h2=ticklabelinside(h(3),'y'); title('ticklabelinside(h(3),''y'')'), xlabel('outside'), ylabel('inside')
%      h(4)=subplot(224); plot(x,x.^2,'r.-',x,.5*x.^2+50,'r.-'), h3=ticklabelinside(h(4),'xy',1); title('ticklabelinside(h(4),''xy'',1)'), xlabel('inside w/corners'), ylabel('inside w/corners')
%
%   Example 2: A big plot with many subplots. 
%      h=subplotsCM(3,4); for n=1:numel(h),plot(h(n),1:10,rand(1,10),'.-'), end, hh=ticklabelinside(h);
%
%   See also: SUBPLOTSCM, ROTATETICKLABEL (both on the file exchange)

%   Written by Andrew Bliss, April 2013

%parse inputs
if nargin<3
    cornerflag=0;
end
if nargin<2
    ax='xy';
end
if nargin==0
    h=gcf;
end
if strcmp(get(h,'type'),'figure')
    hc=get(h,'children');
    h=hc(strcmp(get(hc,'type'),'axes')); %get rid of children that are not axes
    h=h(strcmp(get(h,'tag'),'')); %get rid of axes that are not for plots (e.g. legends)
end

%initialize handles
hout=[];

%loop over all axes
for n=1:numel(h)
    %if axis is invisible, skip it
    if strcmp(get(h(n),'Visible'),'off')
        continue
    end
    %initialize handles to text objects
    h1=[]; h2=[];

    %replace xticklabels with text labels inside the axis
    if strcmp(ax,'x') || strcmp(ax,'xy')
        %get axis properties
        xtick=get(h(n),'xtick');
        xticklabel=get(h(n),'xticklabel');
        axlim=get(h(n),'xlim');
        %reformat labels
        xticklabel=tickformat(xticklabel,xtick);
        %normalized x positions
        xticknorm=(xtick-axlim(1))/(axlim(2)-axlim(1));
        if cornerflag
            ind=true(size(xticknorm)); %print numbers at the corners. Best practice is probably to set axis limits appropriately and use this option.
        elseif ~cornerflag
            ind=xticknorm ~=0 & xticknorm~=1; %don't print numbers at the corners.
        end
        ypos=.05; %y position for text. ranges from .05 to .08 for different size fonts and plots
        h1=text(xticknorm(ind),repmat(ypos,1,sum(ind)),xticklabel(ind),... %looks a little stretched (centers aren't quite on target). oh well.
            'units','normalized','horizontalalignment','center','fontsize',get(h(n),'fontsize'),'parent',h(n));
        set(h(n),'xticklabel',[])
    end
    
    %replace yticklabels with text labels inside the axis
    if strcmp(ax,'y') || strcmp(ax,'xy')
        %get axis properties
        ytick=get(h(n),'ytick');
        yticklabel=get(h(n),'yticklabel');
        axlim=get(h(n),'ylim');
        %reformat labels
        yticklabel=tickformat(yticklabel,ytick);
        %normalized y positions
        yticknorm=(ytick-axlim(1))/(axlim(2)-axlim(1));
        if cornerflag
            ind=true(size(yticknorm)); %print numbers at the corners. Best practice is probably to set axis limits appropriately and use this option.
        elseif ~cornerflag
            ind=yticknorm ~=0 & yticknorm~=1; %don't print numbers at the corners.
        end
        h2=text(repmat(.02,1,sum(ind)),yticknorm(ind),yticklabel(ind),... %looks a little stretched (centers aren't quite on target). oh well.
            'units','normalized','horizontalalignment','left','fontsize',get(h(n),'fontsize'),'parent',h(n));
        set(h(n),'yticklabel',[])
    end
    
    hout=[hout; h1; h2];
end

%concatenate outputs
if nargout
    hh=hout;
end



function ticklabel=tickformat(ticklabel,tick)
%TICKFORMAT adds the exponent to tick labels
ticklabeldbl=str2num(ticklabel); %will be empty if there are any characters
if ~isempty(ticklabeldbl)
    %check for exponent
    if ticklabeldbl(end)~=0
        texp=tick(end)/ticklabeldbl(end); %e.g. 10000
    else
        texp=tick(1)/ticklabeldbl(1);
    end
    texp=log10(texp); %e.g. 4. Should be an integer.
    texp=1/100*round(texp*100); %give it some rounding just to be sure (this avoids a problem with texp being 1e-17)
    %reformat labels
    ticklabel=cellstr(ticklabel);
    if texp~=0
        ticklabel=strcat(ticklabel,['e' num2str(texp)]);
    end
else
    ticklabel=repmat({''},size(tick'));
end
