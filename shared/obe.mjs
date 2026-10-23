export const obeItems=[
 {key:'obe-overview',label:'Overview'},
 {key:'obe-general',label:'General Information',children:[{key:'obe-institute-vision',label:'Institute Vision & Mission'},{key:'obe-department-vision',label:'Department Vision & Mission'}]},
 {key:'obe-setting',label:'Setting',children:[{key:'obe-departments',label:'Departments'},{key:'obe-programmes',label:'Programmes'},{key:'obe-batches',label:'Admission Batch Management'},{key:'obe-semesters',label:'Semester'},{key:'obe-courses',label:'Courses'},{key:'obe-faculty',label:'Faculty from ERP'},{key:'obe-students',label:'Students / Import Student'},{key:'obe-enrolments',label:'Student Course Faculty Mapping'},{key:'obe-erp-links',label:'ERP Links'}]},
 {key:'obe-configuration',label:'OBE Setting',children:[{key:'obe-target',label:'Set Target'},{key:'obe-outcomes',label:'Course Outcomes'},{key:'obe-programme-outcomes',label:'PO/PSO/PEO'},{key:'obe-mapping',label:'CO-PO Mapping'},{key:'obe-university-mapping',label:'University Mapping Question'},{key:'obe-external-marks',label:'External Mark Upload'},{key:'obe-internal-marks',label:'Internal Mark Upload'}]},
 {key:'obe-attainment',label:'Attainment',children:[{key:'obe-articulation',label:'Articulation Matrix'},{key:'obe-mark-attainment',label:'Mark Attainment'},{key:'obe-co-attainment',label:'CO Attainment Calculation'},{key:'obe-po-attainment',label:'PO Attainment'},{key:'obe-pso-attainment',label:'PSO Attainment'}]},
 {key:'obe-reports',label:'Reports',children:[{key:'obe-course-report',label:'Course Wise Report'},{key:'obe-department-report',label:'Department Wise Report'}]}
];
export const obePages=obeItems.flatMap(item=>[item,...(item.children||[])]);
