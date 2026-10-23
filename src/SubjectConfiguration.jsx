import SubjectConfigurationForms from './SubjectConfigurationForms.jsx';
import React from 'react';
import './subject-configuration.css';

export const subjectConfigurationItems=[
 {key:'subject-config-create-semester',label:'Create Semester'},
 {key:'subject-config-assign-subject-teacher',label:'Assign Subject Teacher'},
 {key:'subject-config-allot-class-subject-teacher',label:'Allot Class/Subject/Teacher'},
 {key:'subject-config-allot-substitute-teacher',label:'Allot Substitute Teacher'},
];

export default function SubjectConfiguration({page,onNavigate}){
 const selected=subjectConfigurationItems.find(item=>item.key===page);
 if(!selected)return <section className="subject-configuration-image"><img src="/Sub.png" alt="Subject Configuration"/></section>;
 const kind={'subject-config-create-semester':'semesters','subject-config-assign-subject-teacher':'teachers','subject-config-allot-class-subject-teacher':'allotments','subject-config-allot-substitute-teacher':'substitutes'}[page];
 return <SubjectConfigurationForms key={kind} kind={kind} onNavigate={onNavigate}/>;
}
