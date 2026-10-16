exports.handler=async(e)=>{
 try{
  const {text}=JSON.parse(e.body||'{}');
  const model=process.env.GEMINI_MODEL||'gemini-2.5-flash';
  const prompt='You are an ATS (applicant tracking system) expert. Score this CV from 0-100 for ATS-friendliness (clear sections, keywords, measurable achievements, formatting, contact info, length). Reply ONLY JSON: {"score":number,"tips":"3 short, specific improvement tips in one paragraph"}\n\nCV:\n'+String(text||'').slice(0,12000);
  const r=await fetch(`https://generativelanguage.googleapis.com/v1beta/models/${model}:generateContent?key=${process.env.GEMINI_API_KEY}`,{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({contents:[{parts:[{text:prompt}]}],generationConfig:{responseMimeType:'application/json'}})});
  const j=await r.json();
  const out=JSON.parse(j.candidates[0].content.parts[0].text);
  return {statusCode:200,body:JSON.stringify({score:Math.max(0,Math.min(100,Math.round(out.score))),tips:out.tips})};
 }catch(err){return {statusCode:500,body:JSON.stringify({error:'ATS check failed. Try again in a minute.'})}}
};
