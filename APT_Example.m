%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   the following factors (factor groups) would be considered for the APT example
%   1. market risk premium, i.e., performance of the SP500 Index
%   2. GICS sector factors
%   3. U.S. Dollar movements
%   4. U.S. CPI YoY changes

clc
clear 
load('DataForAPT.mat');

%   the number of stocks in the universe
num_stock=size(stock_mret,1);

%   number of month
num_month=length(date_array);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   the list of factors for which we need calculate stock exposures
factor_list=Factors_desc

%   let's calculate each stock's exposures to those factors
%   each column for one stock (N*(1+M))
beta_mat=nan(num_stock,1+length(Factors_desc));

%   the first column is for the alpha
beta_mat(:,1)=1;

%   fill in the stock exposure for 
for i=1:num_stock

     %   stock monthly returns
     y=stock_mret(i,:)';
     
     %  factor monthly values
     %  note: add an intercept to the independent variable matrix
     X=[ones(length(y),1),Factors_mret'];
     
     %  regression to find the stock's factor exposures over time 
     [b,bint,r]=regress(y,X);
     
     %  record the exposures 
     %  note: the first element in b is the residual 
     beta_mat(i,2:end)=b(2:end)';
     
     
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   add sector risk factors (GICS Sectors)

%   the set of unique sectors (abbreviations)
sector_set=unique(stock_info(:,5))

%   number of sectors 
%   note: to make sure full rank on the column direction, we don't need 11
%   sector identifiers
num_sector=length(sector_set)-1;

%   sector exposure matrix
sector_exposure=zeros(num_stock,num_sector);

%   fill in the exposure value (1 or 0) 
for i=1:num_stock
    [blah,tmp_sector_num]=ismember(stock_info(i,5),sector_set);
    
    if tmp_sector_num<=num_sector
        sector_exposure(i,tmp_sector_num)=1;
    end[A,B,C] = xlsread('HW2.xlsx', 2);t
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   combine the three factors and the sector factors
factor_list=[factor_list;sector_set(1:end-1)];

%   append sector exposures to the beta_mat
beta_mat=[beta_mat,sector_exposure];

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   calculate factor returns at each time point
%   note: based on the second step on Fama-Macbeth regression

%   the total number of factors
num_factor=length(factor_list);

%   pre-allocate memory for the factor return matrix
%   note: each row is for one factor
factor_ret=nan(num_factor,num_month);

%   calculate factor returns at each time point
for t=1:num_month
    
    %   the vector of stocks' returns at time t
    y=stock_mret(:,t);
    
    %   the factor exposures 
    %   note: each row has an array of factors exposures for one stock
    X=beta_mat;
    
    %   run the cross-section regression
    [b,bint,r]=regress(y,X);
    
%     %%%%%%%%%%%%%%%%%%%%%%%
%     %   factor portfolio weight
%     %   note: each row represents a portfolio weight vector
%     %   except for the first row 
%     factor_port=inv(X'*X)*X';
%     
%     %   how to prove long/short neutral for a factor portfolio
%     %   say for the first factor
%     factor_num=2;
%     wt_vec=factor_port(factor_num,:)';
%     sum(wt_vec)==0
%     
%     %   how to prove the factor exposure of the portfolio to other factors
%     X(:,factor_num)'*wt_vec
%     X(:,3)'*wt_vec
   
    
    %   record factors' returns at the time poin t
    factor_ret(:,t)=b(2:end);
    
end

%   now we have a time series of monthly returns for each factor,
%   we can estimate the factor risk premium magnitude for each factor
for k=1:num_factor
    fprintf('--------- %s ------------\n',factor_list{k});
    
    %   the return vector
    tmp_ret=factor_ret(k,:);
    
    %   monthly risk premiun estimate based on mean factor returns
    est_rp=nanmean(tmp_ret);
    
    %   the standard error of this estimate
    se_rp=nanstd(tmp_ret)/sqrt(length(tmp_ret));
    
    %   the t-stats of the estimate
    tstat_rp=est_rp/se_rp;
    
    fprintf('Est Monthly RP = %.2f%%.\n',est_rp);
    fprintf('Std Error.=%.2f%%.\n',se_rp);
    fprintf('T-Stat=%.2f.\n\n',tstat_rp);
end


