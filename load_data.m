%%%%%%%%%%%%%%%%%%%%%%%
clc
clear

%   load stock return info and some market macro data 
filenm='DataSource.xlsx';

datafile='DataForAPT.mat';

%%%%%%%%%%%%%%%%%%%%
%   all stock info 
shnm='StockList';
[blah,blah1,rawraw1]=xlsread(filenm,shnm);

stock_info_desc=rawraw1(1,1:7);
stock_info=rawraw1(2:506,1:7);

%   stock's monthly returns
shnm='StockMonthlyPrices';
[blah2,blah3,rawraw2]=xlsread(filenm,shnm,'C1:HI506');

date_array=datenum(rawraw2(1,:));
tmp_mat=rawraw2(2:end,:);
price_mat=nan(size(tmp_mat));

for i=1:size(price_mat,1)
    for j=1:size(price_mat,2)
        if isnumeric(tmp_mat{i,j})
            price_mat(i,j)=tmp_mat{i,j};
        end
    end
end

stock_mret=price_mat(:,2:end)./price_mat(:,1:end-1)*100-100;

%   each column is a vector of stock returns for one month
date_array=date_array(2:end);

save(datafile,'stock_info_desc','stock_info','stock_mret','date_array');

%%%%%%%%%%%%%%%%%%%%
%   some capm asset returns

shnm='CAPMAssets';
[blah4,blah5,rawraw3]=xlsread(filenm,shnm,'A3:O243');

tmp_date=datenum(rawraw3(2:end,1))';
tmp_spx=cell2mat(rawraw3(2:end,6))';

Factors_desc={'SP500 Index Returns'};

Factors_mret=nan(1,length(date_array));

[IsIn,Pos]=ismember(tmp_date,date_array);
Factors_mret(1,Pos(IsIn))=tmp_spx(IsIn);


%%%%%%%%%%%%%%%%%%%%%
%   add more macro info 
shnm='MacroFactors';
[blah6,blah7,rawraw4]=xlsread(filenm,shnm);


%%%%%%%%%
%   US Dollar Index monthly returns
tmp_date=rawraw4(4:end,1);
tmp_val=cell2mat(rawraw4(4:end,2));
pos=cellfun(@ischar,tmp_date);
tmp_date=datenum(tmp_date(pos));
tmp_val=tmp_val(pos);

%   re-order
[blah,order]=sort(tmp_date,'ascend');
tmp_date=tmp_date(order);
tmp_val=tmp_val(order);

%   get the month-end readins
usd_val=nan(1,length(date_array));
for i=1:length(date_array)
    
    tmp_pos=find(tmp_date<=date_array(i),1,'last');
    
    if ~isempty(tmp_pos)
        usd_val(i)=tmp_val(tmp_pos);
    end
end

usd_ret=[nan,usd_val(2:end)./usd_val(1:end-1)*100-100];

%%%%%%%%%
%   USA monthly CPI YoY 
tmp_date=rawraw4(3:end,4);
tmp_val=cell2mat(rawraw4(3:end,5));
pos=cellfun(@ischar,tmp_date);
tmp_date=datenum(tmp_date(pos));
tmp_val=tmp_val(pos);

%   re-order
[blah8,order]=sort(tmp_date,'ascend');
tmp_date=tmp_date(order);
tmp_val=tmp_val(order);

%   get the month-end readins
cpi_val=nan(1,length(date_array));
[IsIn,Pos]=ismember(tmp_date,date_array);

cpi_val(Pos(IsIn))=tmp_val(IsIn)';

%%%%%%%%%%%%
%   add to the factor set

Factors_desc=[Factors_desc
    {'US Dollar Index Returns'}
    {'US CPI YoY'}
    ];

Factors_mret=[Factors_mret;usd_ret;cpi_val];

save(datafile,'Factors_desc','Factors_mret','-append');
