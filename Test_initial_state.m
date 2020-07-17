function a = Test_initial_state(ciphertext,test_state,feedback_polynomial)

fp_index=find(feedback_polynomial=='1');

L=size(ciphertext(:,1));

output=zeros(L(1,1),1);

for i=1:L(1,1)
    output_bit=mod(sum(test_state(1,fp_index)),2);
    test_state(1,:)=circshift(test_state(1,:),1);
    test_state(1,1)=output_bit;
    output(i,1)=output_bit;
end

a=L(1,1)-2*sum(xor(ciphertext,output(1:L(1,1),1)));