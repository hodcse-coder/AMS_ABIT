export const userManagementItems=[
 {key:'access-assignment',label:'Assignment',children:[{key:'access-assignments',label:'User Assignments'},{key:'access-accounts',label:'Manage Accounts'}]},
 {key:'access-permission',label:'Permission',children:[{key:'access-permission-create',label:'Create Permission'},{key:'access-permissions',label:'Manage Permissions'}]},
 {key:'access-role',label:'Role',children:[{key:'access-role-create',label:'Create Role'},{key:'access-roles',label:'Manage Roles'}]},
 {key:'access-route',label:'Route',children:[{key:'access-routes',label:'Manage Routes'}]}
];
export const userManagementPages=userManagementItems.flatMap(item=>[item,...item.children]);
export const accessModules=[['obe','OBE','/api/admin/obe'],['dashboard-configuration','Dashboard Setup','/api/admin/dashboard-configuration'],['course','Course','/api/admin/course-modules'],['configuration','Configuration','/api/admin/configuration'],['academics','Academics','/api/admin/academics'],['subject-configuration','Subject Configuration','/api/admin/subject-configuration'],['employees','Employee','/api/admin/employees'],['students','Student','/api/admin/students'],['timetable','Timetable','/api/admin/timetable']];
// Whole-module routes include required lookups, nested resources and downloads.
// User/account administration and mentoring-wide access remain Admin-only.
export const registeredAccessRoutes=accessModules.flatMap(([module,label,prefix])=>['GET','POST','PATCH',...(['academics','timetable','obe'].includes(module)?['PUT']:[]),'DELETE'].map(method=>({route_key:module+':'+method.toLowerCase(),module,label:label+' — '+({GET:'View',POST:'Create / Actions',PATCH:'Update',PUT:'Replace',DELETE:'Delete'}[method]),method,path_pattern:prefix+'/**',prefix})));
registeredAccessRoutes.push(...['subjects','academic-years','branches'].map(key=>({route_key:'academics:lookup-'+key,module:'academics',label:'Academics / '+key+' lookup',method:'GET',path_pattern:'/api/admin/course-modules/'+key,prefix:'/api/admin/course-modules/'+key,exact:true}))); 
