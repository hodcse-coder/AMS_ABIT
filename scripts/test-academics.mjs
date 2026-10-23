import assert from 'node:assert/strict';
import {randomBytes} from 'node:crypto';
import {pool} from '../server/db.mjs';
import {hashPassword} from '../server/passwords.mjs';
const base=process.env.TEST_URL||'http://127.0.0.1:3000',root='/api/admin/course-modules',suffix=randomBytes(5).toString('hex'),users=[];
const yearIds=[];let courseId,branchId,secondBranchId;
async function request(path,{cookie,data,...options}={}){return fetch(base+path,{...options,headers:{Origin:base,'Content-Type':'application/json',...(cookie?{Cookie:cookie}:{})},...(data?{body:JSON.stringify(data)}:{})});}
async function login(role){const username=`academic_test_${role}_${suffix}`,password=randomBytes(18).toString('hex');const result=await pool.query('INSERT INTO users(role_id,username,password_hash,full_name) SELECT role_id,$1,$2,$3 FROM user_roles WHERE role_name=$4 RETURNING user_id',[username,await hashPassword(password),'Academic test',role]);users.push(result.rows[0].user_id);const response=await request('/api/login',{method:'POST',data:{username,password,role}});assert.equal(response.status,200);return response.headers.get('set-cookie').split(';')[0];}
try{
 assert.equal((await request(root+'/academic-years')).status,401);
 const cookie=await login('Admin'),faculty=await login('Faculty');assert.equal((await request(root+'/subjects',{cookie:faculty})).status,403);
 assert.equal((await request(root+'/academic-years',{cookie,method:'POST',data:{academic_year:'2026-29'}})).status,400);
 const occupied=new Set((await pool.query('SELECT academic_year FROM academic_years')).rows.map(row=>row.academic_year));
 let start=2200;const labels=[];while(labels.length<2){const label=`${start}-${String((start+1)%100).padStart(2,'0')}`;if(!occupied.has(label))labels.push(label);start++;}
 for(const label of labels){const response=await request(root+'/academic-years',{cookie,method:'POST',data:{academic_year:label}});assert.equal(response.status,201);yearIds.push((await response.json()).id);}
 assert.equal((await request(root+'/academic-years',{cookie,method:'POST',data:{academic_year:labels[0]}})).status,409);
 const years=(await(await request(root+'/academic-years',{cookie})).json()).years;
 for(const id of yearIds)assert.deepEqual(years.find(year=>year.academic_year_id===id).semesters,[1,2]);
 courseId=(await pool.query('INSERT INTO courses(course_name,course_code,course_alias,course_duration,created_by) VALUES($1,$1,$1,4,$2) RETURNING course_id',['ACADEMIC_TEST_'+suffix,users[0]])).rows[0].course_id;
 branchId=(await pool.query("INSERT INTO academic_branches(course_id,branch_code,branch_alias,branch_name) VALUES($1,'A','A','TEST A') RETURNING branch_id",[courseId])).rows[0].branch_id;
 secondBranchId=(await pool.query("INSERT INTO academic_branches(course_id,branch_code,branch_alias,branch_name) VALUES($1,'B','B','TEST B') RETURNING branch_id",[courseId])).rows[0].branch_id;
 const input={branch_id:branchId,academic_year_id:yearIds[0],semester:1,subject_name:'Applied physics',subject_code:`PHY${suffix}`,subject_alias:'Physics',subject_type:'T',credit:0};
 const created=await request(root+'/subjects',{cookie,method:'POST',data:input});assert.equal(created.status,201);const subjectId=(await created.json()).id;
 let subjects=(await(await request(root+'/subjects',{cookie})).json()).subjects;const subject=subjects.find(row=>row.subject_id===subjectId);assert.equal(subject.subject_name,'APPLIED PHYSICS');assert.equal(subject.subject_alias,'PHYSICS');assert.equal(subject.credit,0);assert.equal(subject.branch_id,branchId);assert.equal(subject.branch_name,'TEST A');assert.equal(subject.academic_year,labels[0]);
 assert.equal((await request(root+'/subjects',{cookie,method:'POST',data:input})).status,409);
 assert.equal((await request(root+'/subjects',{cookie,method:'POST',data:{...input,semester:3}})).status,400);
 assert.equal((await request(root+'/subjects',{cookie,method:'POST',data:{...input,subject_type:'INVALID'}})).status,400);
 assert.equal((await request(root+'/subjects',{cookie,method:'POST',data:{...input,credit:-1}})).status,400);
 assert.equal((await request(root+'/subjects',{cookie,method:'POST',data:{...input,branch_id:''}})).status,400);
 const otherBranch=await request(root+'/subjects',{cookie,method:'POST',data:{...input,branch_id:secondBranchId}});assert.equal(otherBranch.status,201);
 const semesterTwo=await request(root+'/subjects',{cookie,method:'POST',data:{...input,semester:2}});assert.equal(semesterTwo.status,201);
 assert.equal((await request(`${root}/academic-years/${yearIds[0]}`,{cookie,method:'DELETE'})).status,409);
 await assert.rejects(pool.query('UPDATE subjects SET semester=3 WHERE subject_id=$1',[subjectId]),error=>error.code==='23503');
 const update={...input,branch_id:secondBranchId,academic_year_id:yearIds[1],subject_name:'Physics lab',subject_type:'P',credit:2};assert.equal((await request(`${root}/subjects/${subjectId}`,{cookie,method:'PATCH',data:update})).status,200);
 subjects=(await(await request(root+'/subjects',{cookie})).json()).subjects;const edited=subjects.find(row=>row.subject_id===subjectId);assert.equal(edited.academic_year,labels[1]);assert.equal(edited.subject_type,'P');assert.equal(edited.updated_by,users[0]);assert.equal(edited.branch_id,secondBranchId);
 assert.equal((await request(`${root}/subjects/${subjectId}`,{cookie,method:'DELETE'})).status,200);
 const secondId=(await semesterTwo.json()).id;assert.equal((await request(`${root}/subjects/${secondId}`,{cookie,method:'DELETE'})).status,200);
 assert.equal((await request(root+'/subjects/'+(await otherBranch.json()).id,{cookie,method:'DELETE'})).status,200);
 let renamed='2300-01';while(occupied.has(renamed)||labels.includes(renamed)){const y=Number(renamed.slice(0,4))+1;renamed=`${y}-${String((y+1)%100).padStart(2,'0')}`;}
 assert.equal((await request(`${root}/academic-years/${yearIds[0]}`,{cookie,method:'PATCH',data:{academic_year:renamed}})).status,200);
 for(const id of yearIds)assert.equal((await request(`${root}/academic-years/${id}`,{cookie,method:'DELETE'})).status,200);
 console.log('PASS: Academic Year CRUD/format/uniqueness, both mapped semesters, Subject CRUD/credit/uppercase/duplicates, database mapping enforcement, linked-year protection and Admin authorization.');
}finally{
 await pool.query('DELETE FROM subjects WHERE created_by=ANY($1::bigint[])',[users]);
 await pool.query('DELETE FROM academic_years WHERE academic_year_id=ANY($1::bigint[])',[yearIds]);
 if(courseId){await pool.query('DELETE FROM academic_branches WHERE course_id=$1',[courseId]);await pool.query('DELETE FROM courses WHERE course_id=$1',[courseId]);}
 await pool.query('DELETE FROM users WHERE user_id=ANY($1::bigint[])',[users]);await pool.end();
}
