%This function creates the output from the combiner presented as Option #3 in the report Individual project task 4

function combiner_output = Option3(initial_states,feedback_polynomials,length)


fp_index1=cell2mat(feedback_polynomials(1,:))=='1';
fp_index2=cell2mat(feedback_polynomials(2,:))=='1';
fp_index3=cell2mat(feedback_polynomials(3,:))=='1';



combiner_output=zeros(length,1);

lfsr1=initial_states{1,1};
lfsr2=initial_states{2,1};
lfsr3=initial_states{3,1};

for i=1:length
    output_bit1=mod(sum(lfsr1(1,fp_index1)),2);
    lfsr1(1,:)=circshift(lfsr1(1,:),1);
    lfsr1(1,1)=output_bit1;
    
    output_bit2=mod(sum(lfsr2(1,fp_index2)),2);
    lfsr2(1,:)=circshift(lfsr2(1,:),1);
    lfsr2(1,1)=output_bit2;
    
    output_bit3=mod(sum(lfsr3(1,fp_index3)),2);
    lfsr3(1,:)=circshift(lfsr3(1,:),1);
    lfsr3(1,1)=output_bit3;
    
    
    combiner_output(i,1)=mod(sum(and(output_bit2,output_bit3)+and(output_bit1,output_bit3)+and(output_bit1,output_bit2)+and(and(output_bit1,output_bit2),output_bit3)),2);

    
end



