import {pool} from './db.mjs';
const base='/api/admin/academics/video-lecture';
const fail=message=>{throw Object.assign(new Error(message),{status:400});};

export async function handleVideoLectures(req,res,path,user,body,reply){
 if(path!==base&&!path.startsWith(base+'/'))return false;
 if(path===base&&req.method==='GET'){
  const {rows}=await pool.query(`SELECT v.l_id,v.related_subject,v.brief_description,v.video_url,v.created_at,v.created_by,v.file_name,v.file_type,v.file_size,
   (COALESCE(octet_length(v.file_data),0)>0) AS uploaded,s.subject_name,s.subject_code,u.full_name AS uploaded_by
   FROM videolecture v LEFT JOIN subjects s ON s.subject_id=v.related_subject LEFT JOIN users u ON u.user_id=v.created_by ORDER BY v.l_id DESC`);
  reply(res,200,{records:rows});return true;
 }
 if(path===base&&req.method==='POST'){
  const input=await body(req),subjectId=Number(input?.related_subject),description=typeof input?.brief_description==='string'?input.brief_description.trim():'';
  const url=typeof input?.video_url==='string'?input.video_url.trim():'';
  if(!Number.isSafeInteger(subjectId)||subjectId<=0||!description||description.length>2000)fail('Select a Subject and enter a Video Description of up to 2000 characters.');
  const encoded=input.file_base64;let bytes=null,name=null,type=null;
  if(url&&encoded)fail('Provide a Video URL or upload a video, choosing one source.');
  if(url){let parsed;try{parsed=new URL(url);}catch{fail('Enter a valid http or https Video URL.');}if(!['http:','https:'].includes(parsed.protocol)||parsed.username||parsed.password||url.length>2000)fail('Enter a valid http or https Video URL.');}
  else{
   name=typeof input.file_name==='string'?input.file_name.trim():'';
   if(!name||name.length>255||/[\x00-\x1f\x7f/\\]/.test(name))fail('Choose a video file with a valid filename.');
   if(typeof encoded!=='string'||!encoded||encoded.length>34952536||encoded.length%4!==0||!/^[A-Za-z0-9+/]+={0,2}$/.test(encoded))fail('Choose an MP4, WebM or OGV video up to 25 MB.');
   bytes=Buffer.from(encoded,'base64');
   if(!bytes.length||bytes.length>26214400||bytes.toString('base64')!==encoded)fail('Choose a nonempty video up to 25 MB.');
   const extension=name.split('.').pop().toLowerCase();
   const valid=extension==='mp4'?bytes.subarray(4,8).toString()==='ftyp':extension==='webm'?bytes.subarray(0,4).equals(Buffer.from('1a45dfa3','hex')):extension==='ogv'?bytes.subarray(0,4).toString()==='OggS':false;
   if(!valid)fail('Choose a valid MP4, WebM or OGV video.');
   type={mp4:'video/mp4',webm:'video/webm',ogv:'video/ogg'}[extension];
  }
  const client=await pool.connect();try{
   await client.query('BEGIN');
   if(!(await client.query('SELECT subject_id FROM subjects WHERE subject_id=$1 FOR SHARE',[subjectId])).rowCount)fail('Selected Subject no longer exists.');
   const result=await client.query(`INSERT INTO videolecture(related_subject,brief_description,video_url,file_name,file_type,file_size,file_data,created_at,created_by,is_status)
    VALUES($1,$2,$3,$4,$5,$6,$7,NOW(),$8,1) RETURNING l_id`,[subjectId,description,url,name,type,bytes?.length??null,bytes,user.user_id]);
   await client.query('COMMIT');reply(res,201,{ok:true,id:result.rows[0].l_id});
  }catch(error){await client.query('ROLLBACK');throw error;}finally{client.release();}return true;
 }
 const remove=path.match(/^\/api\/admin\/academics\/video-lecture\/(\d+)$/);
 if(remove&&req.method==='DELETE'){
  const result=await pool.query('DELETE FROM videolecture WHERE l_id=$1 RETURNING l_id',[remove[1]]);
  reply(res,result.rowCount?200:404,result.rowCount?{ok:true}:{error:'Video lecture not found.'});return true;
 }
 const media=path.match(/^\/api\/admin\/academics\/video-lecture\/(\d+)\/media$/);
 if(media&&req.method==='GET'){
  const video=(await pool.query('SELECT file_data,file_type FROM videolecture WHERE l_id=$1',[media[1]])).rows[0];
  if(!video?.file_data?.length){reply(res,404,{error:'Uploaded video not found.'});return true;}
  const size=video.file_data.length,range=req.headers?.range;
  const headers={'Content-Type':video.file_type,'Accept-Ranges':'bytes','Cache-Control':'private, no-store','X-Content-Type-Options':'nosniff'};
  if(range){
   const match=range.match(/^bytes=(\d*)-(\d*)$/);let start=0,end=size-1;
   if(match&&(match[1]||match[2])){
    if(match[1]){start=Number(match[1]);if(match[2])end=Math.min(Number(match[2]),end);}
    else start=Math.max(0,size-Number(match[2]));
   }
   if(!match||(!match[1]&&!match[2])||!Number.isSafeInteger(start)||!Number.isSafeInteger(end)||start>=size||end<start||(!match[1]&&Number(match[2])===0)){
    res.writeHead(416,{'Content-Range':`bytes */${size}`,'Cache-Control':'no-store'});res.end();return true;
   }
   const chunk=video.file_data.subarray(start,end+1);res.writeHead(206,{...headers,'Content-Range':`bytes ${start}-${end}/${size}`,'Content-Length':chunk.length});res.end(chunk);
  }else{res.writeHead(200,{...headers,'Content-Length':size});res.end(video.file_data);}return true;
 }
 reply(res,405,{error:'Method not allowed.'});return true;
}
