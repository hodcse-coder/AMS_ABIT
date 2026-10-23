export const mentoringItems=[
 {key:'mentoring-sessions',label:'Mentoring',children:[{key:'mentoring-existing',label:'Existing Student'}]},
 {key:'mentoring-first-review',label:'1st Reviewer Remarks'},
 {key:'mentoring-all-reviews',label:'All Counselling & Reviews'},
 {key:'mentoring-reviewers',label:'Reviewer Allotment'},
 {key:'mentoring-allotment',label:'Mentor Allotment',children:[{key:'mentoring-allot-existing',label:'Existing Student'}]},
 {key:'mentoring-report',label:'Mentor Allotment Report'}
];
export const mentoringPages=mentoringItems.flatMap(item=>[item,...(item.children||[])]);
export const discussionTypes=['Academic','Attendance','Behaviour','Personal','Financial','Other'];
export const discussionWith=[['S','Student'],['P','Parent/Guardian'],['B','Student & Parent/Guardian']];
export const counsellingStatus=['Pending Review','Under Review','Reviewed'];
export function mentoringNavigation(admin){return admin?mentoringItems:mentoringItems.filter(item=>!['mentoring-reviewers','mentoring-allotment'].includes(item.key));}
