%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   build a portfolio based on Capital Asset Pricing Model
%   note: assuming risk-free rate of 0
%   Our Hypothesis: Stock Alpha Is Persistent (Note: this is a momentum
%   strategy)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   the stock selection and portfolio construction is as follows:
%   Step 1: at each month-end date, we calculate CAPM-implied idiosyncractic mean
%   returns (security's Jensen's alpha) of all stocks based on past 3 years of observations

%   Step 2: based on the results of Step 1, we include all stocks in the
%   top quartile based on their alpha rankings, and build an equal-weighted
%   portfolio

%   Step 3: the portfolio would be held for one month and be rebalanced at
%   each month-end date
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

clear all;
clc;
load('DataForAPT.mat');

%   number of stocks
num_stock=size(stock_mret,2);

%   look-back period for observing stock beta
%   in default, we'll use past 36 months
lb_month=3*12;

%   starting from 2004-12-31 (so we have enough observations)
reb_start_pos=find(date_array==datenum(2004,12,31));

%   pre-allocate memory for the portfolio's monthly return
port_mret=nan(length(date_array),1);

%   warning off for regress()
warning('off');

%   build the portfolio 
for cur_date_pos=reb_start_pos:length(date_array)-1
    
    %   at the current date point, we need to calculate each stock's
    %   historical market beta, and their alphas
    stock_alpha=nan(num_stock,1);
    stock_beta=nan(num_stock,1);

    %   go through each stock
    for i=1:num_stock
    
        %   the stock's historical returns
        tmp_stock_ret=stock_mret(i,max(1,cur_date_pos-lb_month+1):cur_date_pos)';
        
        %   the SP500's historical returns
        tmp_spx_ret=Factors_mret(1,max(1,cur_date_pos-lb_month+1):cur_date_pos)';
        
        %   skip if there is no enough observation
        %   i.e., ignore those stocks which have too few info
        if sum(~isnan(tmp_stock_ret))<lb_month
            continue;
        end
        
        %   calculate the beta and alpha
        %   based on OLS linear regression (OLS: ordinary least square)
        [b,bint,r]=regress(tmp_stock_ret,[ones(length(tmp_stock_ret),1),tmp_spx_ret]);
        
        %   record the info in b
        %   the first coefficient the alpha, and the second is the stock's
        %   beta exposure
        stock_alpha(i)=b(1);
        stock_beta(i)=b(2);
    end
    
    
    %   locate all the stocks within top-quartile based on their observed
    %   alphas
    
    %   only consider stocks with valid alpha values
    valid_pos=find(~isnan(stock_alpha));
    
    %   sort the alphas on descending order
    [blah,order]=sort(stock_alpha(valid_pos),'descend');
    
    %   the stocks selected
    stock_sel=valid_pos(order(1:floor(length(order)/4)));
    
    %   equal weighting those selected stocks
    wt_vec=ones(length(stock_sel),1);
    wt_vec=wt_vec/sum(wt_vec);
    
    %   the expected aggregate beta for the portfolio
    agg_beta=wt_vec'*stock_beta(stock_sel);
    
    %   maintain beta-one portfolio
    wt_vec=wt_vec/agg_beta;
    
    %   those stocks' returns in the following month
    mret_next=stock_mret(stock_sel,cur_date_pos+1);
    mret_next(isnan(mret_next))=0;
    
    %   calculate the portfolio's return
    port_mret(cur_date_pos+1)=mret_next'*wt_vec;
    
end

%%%%%%%%%%%%%%%%%%%%%
%   performance summary

%   valid date positions
date_pos=reb_start_pos+1:length(date_array);

%   transform the date array so we can use to plot portfolio value chart
dvec=datevec(date_array(date_pos));
x_date=nan(1,length(date_pos));
for i=1:length(date_pos)
    x_date(i)=dvec(i,1)+dvec(i,2)/12;
end

%   calendar years
year_vec=unique(dvec(:,1));

%   plot the portfolio value and the benchmark's value
port_val=100*cumprod(1+0.01*port_mret(date_pos));
bnch_val=100*cumprod(1+0.01*Factors_mret(1,date_pos));

figure;
plot(x_date,port_val,'b');
hold on;
plot(x_date,bnch_val,'k');
legend({'Our Portfolio','S&P500 Index'});
title('Portfolio Cumulative Performance');


%   calendar year returns
fprintf('--------------- Calendar Year Performance (%%) -------------------------\n');
fprintf('\t Portfolio \t S&P500\n');
for i=1:length(year_vec)

    %   all positions for the year
    tmp_pos=find(dvec(:,1)==year_vec(i));
    
    %   calculate calendar year returns
    tmp_port=prod(1+0.01*port_mret(date_pos(tmp_pos)))*100-100;
    tmp_bnch=prod(1+0.01*Factors_mret(1,date_pos(tmp_pos)))*100-100;
    
    %   output the returns
    fprintf('%d:\t%.2f\t%.2f\n',year_vec(i),tmp_port,tmp_bnch);
end

%   sharpe ratio
tmp_port=port_mret(date_pos);
tmp_bnch=Factors_mret(1,date_pos)';

sr_port=nanmean(tmp_port)/nanstd(tmp_port)*sqrt(12);
sr_bnch=nanmean(tmp_bnch)/nanstd(tmp_bnch)*sqrt(12);
fprintf('Ann SR:\t%.2f\t%.2f\n',sr_port,sr_bnch);

%   hit ratio
fprintf('Hit Ratio: %.1f%%\n',100*sum(tmp_port>tmp_bnch)/length(tmp_bnch));



