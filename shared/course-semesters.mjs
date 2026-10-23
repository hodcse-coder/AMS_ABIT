export function courseSemesterCount(duration){
 const count=Number(duration)*2;
 return Number.isInteger(count)&&count>0&&count<=32767?count:0;
}
export function courseSemesterOptions(duration){
 return Array.from({length:courseSemesterCount(duration)},(_,index)=>{
  const number=index+1,ending=number%100;
  const suffix=ending>=11&&ending<=13?'TH':({1:'ST',2:'ND',3:'RD'}[number%10]||'TH');
  return [number,`${number}${suffix}`];
 });
}
