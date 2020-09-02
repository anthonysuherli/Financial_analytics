function [c,ceq]=nonlcon(w,b_vec,const)
c=const-b_vec'*log(w);
ceq=[];
end
