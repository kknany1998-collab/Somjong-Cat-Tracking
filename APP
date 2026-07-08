import { useState, useRef, useEffect } from "react";
import { LineChart, Line, BarChart, Bar, PieChart, Pie, Cell, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer } from "recharts";
import { createClient } from "@supabase/supabase-js";

const supabase = createClient(
  import.meta.env.VITE_SUPABASE_URL,
  import.meta.env.VITE_SUPABASE_ANON_KEY
);
const ROW_ID = "somjong"; // single shared row - everyone reads/writes this same record

const C = {
  cream: "#FFF8F0", orange: "#FF8C42", orangeLight: "#FFE4CC",
  blue: "#7EC8E3", blueLight: "#EAF7FC", green: "#6BCB77",
  red: "#FF6B6B", purple: "#C77DFF", gray: "#6B7280",
  grayLight: "#F3F4F6", text: "#1F2937", card: "rgba(255,255,255,0.92)",
};

// ── Modal Overlay ─────────────────────────────────────────────────────
function Modal({ title, onClose, children }) {
  return (
    <div
      onClick={onClose}
      style={{ position:"fixed", inset:0, background:"rgba(20,15,10,0.5)", zIndex:1000, display:"flex", alignItems:"center", justifyContent:"center", padding:16 }}
    >
      <div
        onClick={e=>e.stopPropagation()}
        style={{ background:"#fff", border:`2px solid ${C.orange}`, borderRadius:20, overflow:"hidden", width:"100%", maxWidth:420, maxHeight:"85vh", display:"flex", flexDirection:"column", boxShadow:"0 12px 40px rgba(0,0,0,0.3)" }}
      >
        <div style={{ display:"flex", alignItems:"center", justifyContent:"space-between", padding:"14px 18px", borderBottom:`1px solid ${C.grayLight}`, background:C.orangeLight, flexShrink:0 }}>
          <div style={{ fontWeight:700, fontSize:15, color:C.orange }}>{title}</div>
          <button type="button" onClick={onClose} style={{ background:C.orange, border:"none", borderRadius:"50%", width:28, height:28, cursor:"pointer", fontSize:14, color:"#fff", display:"flex", alignItems:"center", justifyContent:"center", fontWeight:700, flexShrink:0 }}>✕</button>
        </div>
        <div style={{ padding:"16px 18px", overflowY:"auto" }}>{children}</div>
      </div>
    </div>
  );
}

// ── Confirm Dialog ────────────────────────────────────────────────────
function Confirm({ msg, onConfirm, onCancel }) {
  return (
    <div onClick={onCancel} style={{ position:"fixed", inset:0, background:"rgba(20,15,10,0.5)", zIndex:1000, display:"flex", alignItems:"center", justifyContent:"center", padding:16 }}>
      <div onClick={e=>e.stopPropagation()} style={{ background:"#fff", border:`2px solid ${C.red}`, borderRadius:20, overflow:"hidden", width:"100%", maxWidth:360, boxShadow:"0 12px 40px rgba(0,0,0,0.3)" }}>
        <div style={{ background:"#FFF0F0", padding:"16px 18px", borderBottom:`1px solid #FFD0D0`, textAlign:"center" }}>
          <div style={{ fontSize:28, marginBottom:6 }}>⚠️</div>
          <div style={{ fontSize:14, color:C.text, lineHeight:1.6 }}>{msg}</div>
        </div>
        <div style={{ display:"flex", gap:10, padding:"14px 18px" }}>
          <button type="button" onClick={onCancel} style={{ flex:1, padding:"10px 0", borderRadius:12, border:`1.5px solid ${C.grayLight}`, background:"#fff", cursor:"pointer", fontWeight:600, fontSize:14 }}>ยกเลิก</button>
          <button type="button" onClick={onConfirm} style={{ flex:1, padding:"10px 0", borderRadius:12, border:"none", background:C.red, color:"#fff", cursor:"pointer", fontWeight:700, fontSize:14 }}>ลบ</button>
        </div>
      </div>
    </div>
  );
}

// ── Form Field ────────────────────────────────────────────────────────
function Field({ label, value, onChange, type="text", options, rows }) {
  const base = { width:"100%", border:`1.5px solid #E5E7EB`, borderRadius:10, padding:"8px 12px", fontSize:13, outline:"none", boxSizing:"border-box", fontFamily:"inherit", background:"#fff" };
  return (
    <div style={{ marginBottom:12 }}>
      <div style={{ fontSize:12, color:C.gray, fontWeight:600, marginBottom:4 }}>{label}</div>
      {options ? (
        <select value={value} onChange={e=>onChange(e.target.value)} style={base}>
          {options.map(o=><option key={o} value={o}>{o}</option>)}
        </select>
      ) : rows ? (
        <textarea value={value} onChange={e=>onChange(e.target.value)} rows={rows} style={{...base, resize:"vertical"}} />
      ) : (
        <input type={type} value={value} onChange={e=>onChange(e.target.value)} style={base} />
      )}
    </div>
  );
}

// ── File/Image Input ─────────────────────────────────────────────────
function FileInput({ label, value, onChange }) {
  const inputRef = useRef(null);
  const handleFile = (e) => {
    const file = e.target.files && e.target.files[0];
    if (!file) return;
    const reader = new FileReader();
    reader.onload = () => onChange(reader.result);
    reader.readAsDataURL(file);
  };
  return (
    <div style={{ marginBottom:12 }}>
      <div style={{ fontSize:12, color:C.gray, fontWeight:600, marginBottom:4 }}>{label}</div>
      {value ? (
        <div style={{ position:"relative", display:"inline-block" }}>
          <img src={value} alt={label} style={{ maxWidth:"100%", maxHeight:140, borderRadius:10, border:`1.5px solid #E5E7EB`, display:"block" }}/>
          <button type="button" onClick={()=>{ onChange(""); if(inputRef.current) inputRef.current.value=""; }}
            style={{ position:"absolute", top:-8, right:-8, background:C.red, color:"#fff", border:"2px solid #fff", borderRadius:"50%", width:24, height:24, cursor:"pointer", fontSize:12, fontWeight:700 }}>✕</button>
        </div>
      ) : (
        <label style={{ display:"flex", alignItems:"center", justifyContent:"center", gap:6, border:`1.5px dashed #D1D5DB`, borderRadius:10, padding:"14px 12px", cursor:"pointer", color:C.gray, fontSize:12, background:C.grayLight }}>
          📎 แนบรูป
          <input ref={inputRef} type="file" accept="image/*" onChange={handleFile} style={{ display:"none" }}/>
        </label>
      )}
    </div>
  );
}

// ── Buttons ───────────────────────────────────────────────────────────
const Btn = ({ label, onClick, color=C.orange, outline=false, small=false }) => (
  <button type="button" onClick={onClick} style={{ background:outline?"#fff":color, color:outline?color:"#fff", border:`1.5px solid ${color}`, borderRadius:small?99:12, padding:small?"4px 10px":"10px 0", fontSize:small?11:14, fontWeight:700, cursor:"pointer", width:outline||small?"auto":"100%", paddingLeft:small?10:undefined, paddingRight:small?10:undefined }}>
    {label}
  </button>
);
const IconBtn = ({ icon, onClick, color=C.orange }) => (
  <button
    type="button"
    onClick={(e)=>{ e.preventDefault(); e.stopPropagation(); onClick(e); }}
    style={{ background:color+"18", color, border:"none", borderRadius:8, width:28, height:28, cursor:"pointer", fontSize:14, display:"flex", alignItems:"center", justifyContent:"center", flexShrink:0, position:"relative", zIndex:5 }}
  >{icon}</button>
);

// ── Card ──────────────────────────────────────────────────────────────
const Card = ({ children, style={} }) => (
  <div style={{ background:C.card, borderRadius:20, padding:18, backdropFilter:"blur(12px)", boxShadow:"0 2px 16px rgba(0,0,0,0.07)", ...style }}>{children}</div>
);
const SectionTitle = ({ icon, title, onAdd }) => (
  <div style={{ display:"flex", alignItems:"center", justifyContent:"space-between", marginBottom:12 }}>
    <div style={{ display:"flex", alignItems:"center", gap:8 }}>
      <span style={{ fontSize:18 }}>{icon}</span>
      <span style={{ fontWeight:700, fontSize:16, color:C.text }}>{title}</span>
    </div>
    {onAdd && <button type="button" onClick={onAdd} style={{ background:C.orangeLight, color:C.orange, border:"none", borderRadius:99, padding:"4px 12px", fontSize:12, fontWeight:700, cursor:"pointer" }}>+ เพิ่ม</button>}
  </div>
);
const Badge = ({ label, color=C.orange }) => (
  <span style={{ background:color+"22", color, borderRadius:99, padding:"2px 10px", fontSize:11, fontWeight:600 }}>{label}</span>
);
const ProgressRing = ({ pct, size=80, stroke=8, color=C.orange, label, sublabel }) => {
  const r=(size-stroke)/2, circ=2*Math.PI*r, dash=circ*(pct/100);
  return (
    <div style={{ position:"relative", width:size, height:size }}>
      <svg width={size} height={size} style={{ transform:"rotate(-90deg)" }}>
        <circle cx={size/2} cy={size/2} r={r} fill="none" stroke="#F3F4F6" strokeWidth={stroke}/>
        <circle cx={size/2} cy={size/2} r={r} fill="none" stroke={color} strokeWidth={stroke} strokeDasharray={`${dash} ${circ}`} strokeLinecap="round"/>
      </svg>
      <div style={{ position:"absolute", inset:0, display:"flex", flexDirection:"column", alignItems:"center", justifyContent:"center" }}>
        {label && <div style={{ fontSize:size<70?13:16, fontWeight:700, color:C.text }}>{label}</div>}
        {sublabel && <div style={{ fontSize:10, color:C.gray }}>{sublabel}</div>}
      </div>
    </div>
  );
};

// ─────────────────────────────────────────────────────────────────────
// SEED DATA
// ─────────────────────────────────────────────────────────────────────
const SEED_CAT = { name:"สมจ๋อง", breed:"Scottish Fold", sex:"ชาย", bday:"2020-03-15", weight:"4.0", nextAppt:addDays(todayISO(),7), hospital:"รพ.สัตว์เกษตร กำแพงแสน", vet:"น.สพ.สมชาย", motto:"Recovering Every Day" };
const SEED_WEIGHTS = [
  { id:1, date:addDays(todayISO(),-35), w:3.8 },{ id:2, date:addDays(todayISO(),-28), w:3.6 },{ id:3, date:addDays(todayISO(),-21), w:3.5 },
  { id:4, date:addDays(todayISO(),-14), w:3.7 },{ id:5, date:addDays(todayISO(),-7), w:3.9 },{ id:6, date:todayISO(), w:4.0 },
];
const SEED_TL = [
  { id:1, date:todayISO(), time:"09:00", hospital:"รพ.สัตว์เกษตร กำแพงแสน", vet:"น.สพ.สมชาย", diagnosis:"ติดเชื้อทางเดินปัสสาวะ", treatment:"ให้น้ำเกลือ IV, ยาปฏิชีวนะ", cost:"2800", note:"ติดตามอีก 7 วัน", tags:"#ตรวจเลือด,#ฉุกเฉิน" },
  { id:2, date:addDays(todayISO(),-7), time:"14:00", hospital:"รพ.สัตว์เวชชีวิน", vet:"น.สพ.หญิงวิมล", diagnosis:"FLUTD", treatment:"อาหาร Urinary S/O", cost:"1500", note:"ลดปลา เพิ่มน้ำ", tags:"#พักฟื้น" },
  { id:3, date:addDays(todayISO(),-21), time:"10:30", hospital:"รพ.สัตว์เกษตร กำแพงแสน", vet:"น.สพ.สมชาย", diagnosis:"ผ่าตัดก้อนเนื้อ", treatment:"ผ่าตัดและเย็บแผล", cost:"8500", note:"ดูแลแผลวันละ 2 ครั้ง", tags:"#ผ่าตัด" },
];
const SEED_MEDS = [
  { id:1, name:"Amoxicillin", dose:"62.5", unit:"mg", freq:"12", withFood:"หลังอาหาร", start:addDays(todayISO(),-6), end:addDays(todayISO(),7), color:C.orange },
  { id:2, name:"Onsior (Robenacoxib)", dose:"6", unit:"mg", freq:"24", withFood:"พร้อมอาหาร", start:addDays(todayISO(),-6), end:addDays(todayISO(),3), color:C.blue },
  { id:3, name:"Probiotics", dose:"1", unit:"หลอด", freq:"24", withFood:"พร้อมอาหาร", start:addDays(todayISO(),-6), end:addDays(todayISO(),23), color:C.green },
];
const SEED_WATER = [
  { id:1, time:"07:00", ml:"15", done:true },{ id:2, time:"13:00", ml:"12", done:true },
  { id:3, time:"19:00", ml:"14", done:false },{ id:4, time:"01:00", ml:"10", done:false },
];
const SEED_FOOD = [
  { id:1, time:"07:00", label:"เช้า", amount:"½", unit:"ซอง", brand:"Royal Canin Urinary S/O", done:true },
  { id:2, time:"12:00", label:"เที่ยง", amount:"½", unit:"ซอง", brand:"Royal Canin Urinary S/O", done:true },
  { id:3, time:"17:00", label:"เย็น", amount:"½", unit:"ซอง", brand:"Royal Canin Urinary S/O", done:false },
  { id:4, time:"22:00", label:"กลางคืน", amount:"½", unit:"ซอง", brand:"Royal Canin Urinary S/O", done:false },
];
const SEED_STOCK = [
  { id:1, cat:"อาหารเปียก", name:"Royal Canin Urinary S/O", qty:"12", unit:"ซอง", min:"8", price:"55" },
  { id:2, cat:"อาหารเปียก", name:"Hill's c/d Multicare", qty:"6", unit:"ซอง", min:"8", price:"65" },
  { id:3, cat:"ยา", name:"Amoxicillin 250mg", qty:"28", unit:"เม็ด", min:"10", price:"8" },
  { id:4, cat:"อุปกรณ์", name:"ผ้าปูซับฉี่", qty:"5", unit:"ผืน", min:"10", price:"35" },
  { id:5, cat:"อุปกรณ์", name:"ไซริงค์ 5ml", qty:"20", unit:"อัน", min:"5", price:"12" },
];
const SEED_HOSPITALS = [
  { id:1, name:"รพ.สัตว์เกษตร กำแพงแสน", phone:"034-281-080", mapUrl:"https://maps.google.com/?q=Kasetsart+Veterinary+Hospital", vets:"น.สพ.สมชาย ใจดี, น.สพ.หญิงรัตนา มีสุข" },
  { id:2, name:"รพ.สัตว์เวชชีวิน", phone:"02-942-3311", mapUrl:"https://maps.google.com/?q=Wetcheewin+Animal+Hospital", vets:"น.สพ.หญิงวิมล ดีเด่น, น.สพ.ประเสริฐ สุขใจ" },
];
const SEED_CHECK = [
  { id:"water",label:"ดื่มน้ำครบ",done:true,icon:"💧" },{ id:"meds",label:"กินยาครบ",done:true,icon:"💊" },
  { id:"food",label:"กินอาหารครบ",done:false,icon:"🥣" },{ id:"poop",label:"ถ่ายอุจจาระ",done:true,icon:"💩" },
  { id:"pee",label:"ปัสสาวะ",done:true,icon:"🚽" },{ id:"walk",label:"เดินได้",done:true,icon:"🐾" },
  { id:"eat",label:"กินเองได้",done:true,icon:"😋" },{ id:"happy",label:"ร่าเริง",done:false,icon:"😺" },
  { id:"vomit",label:"อาเจียน",done:false,icon:"🤮",inverse:true },{ id:"wound",label:"แผลปกติดี",done:true,icon:"🩹" },
  { id:"fever",label:"ไม่มีไข้",done:true,icon:"🌡️" },
];
const EXPENSE_DATA = [
  { cat:"ค่ารักษา",amount:11300,color:C.orange },{ cat:"ค่ายา",amount:2400,color:C.blue },
  { cat:"ค่าตรวจ",amount:1800,color:C.green },{ cat:"ค่าอาหาร",amount:3200,color:C.purple },{ cat:"ค่าอื่น ๆ",amount:650,color:C.red },
];
const MONTHLY = [
  { month:"ก.พ.",total:3200 },{ month:"มี.ค.",total:4100 },{ month:"เม.ย.",total:2800 },
  { month:"พ.ค.",total:5500 },{ month:"มิ.ย.",total:9700 },{ month:"ก.ค.",total:11300 },
];

function age(bday) {
  const d=new Date(bday), now=new Date();
  let y=now.getFullYear()-d.getFullYear(), m=now.getMonth()-d.getMonth();
  if(m<0){y--;m+=12;} return `${y} ปี ${m} เดือน`;
}
function todayISO() {
  const d = new Date();
  const y = d.getFullYear(), m = String(d.getMonth()+1).padStart(2,"0"), day = String(d.getDate()).padStart(2,"0");
  return `${y}-${m}-${day}`;
}
function addDays(iso, n) {
  const d = new Date(iso + "T00:00:00");
  d.setDate(d.getDate() + n);
  const y = d.getFullYear(), m = String(d.getMonth()+1).padStart(2,"0"), day = String(d.getDate()).padStart(2,"0");
  return `${y}-${m}-${day}`;
}
function nowHHMM() {
  const d = new Date();
  return `${String(d.getHours()).padStart(2,"0")}:${String(d.getMinutes()).padStart(2,"0")}`;
}
const totalExp = EXPENSE_DATA.reduce((s,e)=>s+e.amount,0);
const EMPTY_TL  = { date:"", time:"", hospital:"", vet:"", diagnosis:"", treatment:"", cost:"", note:"", tags:"", photo:"", receipt:"" };
const EMPTY_MED = { name:"", dose:"", unit:"mg", freq:"12", withFood:"หลังอาหาร", start:"", end:"", color:C.orange };
const EMPTY_WTR = { time:"", ml:"" };
const EMPTY_FOOD= { time:"", label:"", amount:"", unit:"ซอง", brand:"", done:false };
const EMPTY_STK = { cat:"อาหารเปียก", name:"", qty:"", unit:"", min:"", price:"" };
const EMPTY_HSP = { name:"", phone:"", mapUrl:"", vets:"" };
const EMPTY_WT  = { date:"", w:"" };

// ─────────────────────────────────────────────────────────────────────
// Dashboard
// ─────────────────────────────────────────────────────────────────────
function Dashboard({ cat, setCat, checklist, setChecklist, weights, setWeights }) {
  const [editCat, setEditCat]=useState(false);
  const [form, setForm]=useState(cat);
  const [editAppt, setEditAppt]=useState(false);
  const [apptForm, setApptForm]=useState({ nextAppt:cat.nextAppt, hospital:cat.hospital, vet:cat.vet });
  const [editWeight, setEditWeight]=useState(null);
  const [wForm, setWForm]=useState(EMPTY_WT);
  const [wUnit, setWUnit]=useState("kg");
  const [confirm, setConfirm]=useState(null);
  const [targetWeight, setTargetWeight]=useState(null);
  const [editTarget, setEditTarget]=useState(false);
  const [targetForm, setTargetForm]=useState("");

  const openEditCat = () => { setForm(cat); setEditCat(true); };
  const saveEdit = ()=>{ setCat(p=>({...p, ...form, nextAppt:p.nextAppt, hospital:p.hospital, vet:p.vet})); setEditCat(false); };

  const openEditAppt = () => { setApptForm({ nextAppt:cat.nextAppt, hospital:cat.hospital, vet:cat.vet }); setEditAppt(true); };
  const saveAppt = () => { setCat(p=>({...p, ...apptForm})); setEditAppt(false); };

  const latestW = weights.length ? weights[weights.length-1].w : "-";
  const prevW   = weights.length>1 ? weights[weights.length-2].w : null;
  const diff    = prevW!=null ? (latestW-prevW).toFixed(1) : null;

  const waterDone = SEED_WATER.filter(w=>w.done).length;
  const healthScore = Math.round((checklist.filter(c=>c.inverse?!c.done:c.done).length/checklist.length)*100);

  const changeWUnit = (u) => {
    setWUnit(prevUnit => {
      if (u !== prevUnit) {
        setWForm(p => {
          const n = parseFloat(p.w);
          if (!Number.isFinite(n)) return p;
          const converted = u === "g" ? n * 1000 : n / 1000;
          // trim to a sane number of decimals depending on unit
          const rounded = u === "g" ? Math.round(converted) : Math.round(converted * 100) / 100;
          return { ...p, w: String(rounded) };
        });
      }
      return u;
    });
  };

  const openAddW = ()=>{ setWForm({date:todayISO(),w:""}); setWUnit("kg"); setEditWeight("new"); };
  const openEditW = (w)=>{ setWForm({date:w.date,w:String(w.w)}); setWUnit("kg"); setEditWeight(w.id); };
  const saveWeight = ()=>{
    if(!wForm.date||!wForm.w) return;
    const kgVal = wUnit==="g" ? parseFloat(wForm.w)/1000 : parseFloat(wForm.w);
    if(!Number.isFinite(kgVal)) return;
    if(editWeight==="new") setWeights(p=>[...p,{id:Date.now(),date:wForm.date,w:kgVal}]);
    else setWeights(p=>p.map(x=>x.id===editWeight?{...x,date:wForm.date,w:kgVal}:x));
    setEditWeight(null);
  };
  const delWeight = (id)=>{ setConfirm({msg:"ลบน้ำหนักนี้?",fn:()=>{ setWeights(p=>p.filter(x=>x.id!==id)); setConfirm(null); }}); };

  const chartData = weights.map(w=>({ date:w.date.slice(5), w:w.w }));

  // ── Weight goal projection (simple linear regression on weight history) ──
  const defaultTarget = (Number(latestW)||0) + 2;
  const goalTarget = targetWeight!=null ? targetWeight : defaultTarget;
  const openEditTarget = ()=>{ setTargetForm(String(goalTarget)); setEditTarget(true); };
  const saveTarget = ()=>{
    const v = parseFloat(targetForm);
    if(Number.isFinite(v)) setTargetWeight(v);
    setEditTarget(false);
  };

  const goalProjection = (() => {
    if (weights.length < 2 || typeof latestW !== "number") return null;
    const pts = weights.map(w => ({ t: new Date(w.date).getTime()/86400000, w: w.w })).filter(p=>Number.isFinite(p.t));
    if (pts.length < 2) return null;
    const n = pts.length;
    const sumT = pts.reduce((s,p)=>s+p.t,0), sumW = pts.reduce((s,p)=>s+p.w,0);
    const meanT = sumT/n, meanW = sumW/n;
    let num=0, den=0;
    pts.forEach(p=>{ num += (p.t-meanT)*(p.w-meanW); den += (p.t-meanT)*(p.t-meanT); });
    const slope = den!==0 ? num/den : 0; // kg per day
    const intercept = meanW - slope*meanT;
    // R^2
    let ssTot=0, ssRes=0;
    pts.forEach(p=>{ const pred = slope*p.t+intercept; ssRes += (p.w-pred)**2; ssTot += (p.w-meanW)**2; });
    const r2 = ssTot>0 ? 1-(ssRes/ssTot) : 0;
    const weeklyRate = slope*7;
    const remaining = goalTarget - latestW;
    let projectedDate = null, daysNeeded = null;
    if (slope > 0.0005 && remaining > 0) {
      daysNeeded = remaining/slope;
      const d = new Date(); d.setDate(d.getDate()+Math.round(daysNeeded));
      projectedDate = d.toISOString().slice(0,10);
    }
    let confidence = "ต่ำ";
    if (r2 >= 0.7) confidence = "สูง"; else if (r2 >= 0.4) confidence = "ปานกลาง";
    return { weeklyRate, remaining, projectedDate, daysNeeded, confidence, r2 };
  })();

  return (
    <div style={{ display:"flex", flexDirection:"column", gap:16 }}>
      {confirm && <Confirm msg={confirm.msg} onConfirm={confirm.fn} onCancel={()=>setConfirm(null)}/>}

      {/* Hero */}
      <Card style={{ background:`linear-gradient(135deg, #FF8C42 0%, #FFB347 100%)`, color:"#fff", position:"relative", overflow:"hidden", padding:24 }}>
        <div style={{ position:"absolute", right:-20, top:-20, fontSize:120, opacity:0.12, pointerEvents:"none" }}>🐈</div>
        <div style={{ display:"flex", alignItems:"center", gap:16 }}>
          <div style={{ width:72, height:72, borderRadius:"50%", background:"rgba(255,255,255,0.25)", display:"flex", alignItems:"center", justifyContent:"center", fontSize:42, border:"3px solid rgba(255,255,255,0.5)", flexShrink:0 }}>🐱</div>
          <div style={{ flex:1 }}>
            <div style={{ fontSize:24, fontWeight:800 }}>{cat.name} ❤️</div>
            <div style={{ fontSize:13, opacity:0.9, marginBottom:4 }}>"{cat.motto}"</div>
            <div style={{ display:"flex", gap:6, flexWrap:"wrap" }}>
              <Badge label={cat.breed} color="#fff"/><Badge label={age(cat.bday)} color="#fff"/><Badge label={cat.sex==="ชาย"?"♂ ชาย":"♀ หญิง"} color="#fff"/>
            </div>
          </div>
          <button type="button" onClick={openEditCat} style={{ background:"rgba(255,255,255,0.25)", border:"1.5px solid rgba(255,255,255,0.5)", borderRadius:10, color:"#fff", padding:"6px 10px", fontSize:12, cursor:"pointer", flexShrink:0, fontWeight:600, position:"relative", zIndex:5 }}>✏️ แก้ไข</button>
        </div>
        <div style={{ display:"grid", gridTemplateColumns:"1fr 1fr 1fr", gap:10, marginTop:16 }}>
          {[
            { label:"น้ำหนักล่าสุด", val:`${latestW} กก.`, sub: diff!=null ? (diff>=0?`▲ +${diff} กก.`:`▼ ${diff} กก.`):"–", onClick:null },
            { label:"ค่ารักษาสะสม", val:`฿${totalExp.toLocaleString()}`, sub:"6 เดือน", onClick:null },
            { label:"นัดต่อไป", val:cat.nextAppt?.slice(5)||"–", sub:cat.hospital?.slice(0,10)||"–", onClick:openEditAppt },
          ].map(s=>(
            <div key={s.label} onClick={s.onClick||undefined} style={{ background:"rgba(255,255,255,0.2)", borderRadius:12, padding:"10px 12px", cursor:s.onClick?"pointer":"default", position:"relative" }}>
              <div style={{ fontSize:10, opacity:0.85 }}>{s.label}{s.onClick && " ✏️"}</div>
              <div style={{ fontSize:15, fontWeight:700 }}>{s.val}</div>
              <div style={{ fontSize:10, opacity:0.75 }}>{s.sub}</div>
            </div>
          ))}
        </div>
      </Card>

      {/* Rings */}
      <div style={{ display:"grid", gridTemplateColumns:"1fr 1fr 1fr", gap:12 }}>
        {[
          { ring:<ProgressRing pct={healthScore} size={72} label={`${healthScore}%`} sublabel="สุขภาพ" color={healthScore>70?C.green:C.orange}/>, sub:"Health Score" },
          { ring:<ProgressRing pct={Math.round((waterDone/SEED_WATER.length)*100)} size={72} label={`${waterDone}/${SEED_WATER.length}`} sublabel="รอบน้ำ" color={C.blue}/>, sub:"น้ำวันนี้" },
          { ring:<ProgressRing pct={healthScore} size={72} label={`${checklist.filter(c=>c.inverse?!c.done:c.done).length}/${checklist.length}`} sublabel="checklist" color={C.purple}/>, sub:"Checklist" },
        ].map((x,i)=>(
          <Card key={i} style={{ display:"flex", flexDirection:"column", alignItems:"center", gap:6, padding:14 }}>
            {x.ring}
            <div style={{ fontSize:11, color:C.gray, textAlign:"center" }}>{x.sub}</div>
          </Card>
        ))}
      </div>

      {/* Daily Checklist */}
      <Card>
        <SectionTitle icon="✅" title="Daily Checklist"/>
        <div style={{ display:"grid", gridTemplateColumns:"1fr 1fr", gap:8 }}>
          {checklist.map(item=>{
            const good=item.inverse?!item.done:item.done;
            return (
              <button type="button" key={item.id} onClick={()=>setChecklist(p=>p.map(c=>c.id===item.id?{...c,done:!c.done}:c))}
                style={{ display:"flex", alignItems:"center", gap:8, background:good?C.green+"18":C.grayLight, borderRadius:12, padding:"10px 12px", border:`1.5px solid ${good?C.green:"#E5E7EB"}`, cursor:"pointer" }}>
                <span style={{ fontSize:18 }}>{item.icon}</span>
                <div style={{ flex:1, fontSize:12, fontWeight:600, color:C.text, textAlign:"left" }}>{item.label}</div>
                <div style={{ width:20, height:20, borderRadius:"50%", background:good?C.green:"#D1D5DB", display:"flex", alignItems:"center", justifyContent:"center", flexShrink:0 }}>
                  {good&&<span style={{ color:"#fff", fontSize:11, fontWeight:700 }}>✓</span>}
                </div>
              </button>
            );
          })}
        </div>
      </Card>

      {/* Weight */}
      <Card>
        <SectionTitle icon="⚖️" title="น้ำหนัก (กก.)" onAdd={openAddW}/>
        <ResponsiveContainer width="100%" height={150}>
          <LineChart data={chartData}>
            <CartesianGrid strokeDasharray="3 3" stroke="#F3F4F6"/>
            <XAxis dataKey="date" tick={{ fontSize:11 }}/><YAxis domain={["auto","auto"]} tick={{ fontSize:11 }}/>
            <Tooltip formatter={v=>`${v} กก.`}/>
            <Line type="monotone" dataKey="w" stroke={C.orange} strokeWidth={2.5} dot={{ fill:C.orange, r:4 }}/>
          </LineChart>
        </ResponsiveContainer>
        <div style={{ display:"flex", flexDirection:"column", gap:6, marginTop:8 }}>
          {[...weights].reverse().slice(0,4).map(w=>(
            <div key={w.id} style={{ display:"flex", alignItems:"center", gap:8, background:C.grayLight, borderRadius:10, padding:"8px 12px" }}>
              <span style={{ fontSize:12, color:C.gray, flex:1 }}>{w.date}</span>
              <span style={{ fontWeight:700, color:C.text }}>{w.w} กก.</span>
              <IconBtn icon="✏️" onClick={()=>openEditW(w)} color={C.orange}/>
              <IconBtn icon="🗑️" onClick={()=>delWeight(w.id)} color={C.red}/>
            </div>
          ))}
        </div>
      </Card>

      {/* Weight Goal */}
      <Card>
        <SectionTitle icon="🎯" title="เป้าหมายน้ำหนัก" onAdd={openEditTarget}/>
        <div style={{ display:"flex", alignItems:"center", justifyContent:"space-between", marginBottom:10 }}>
          <div style={{ fontSize:13, color:C.gray }}>เป้าหมาย: <b style={{ color:C.text }}>{goalTarget.toFixed(1)} กก.</b></div>
          <div style={{ fontSize:13, color:C.gray }}>ปัจจุบัน: <b style={{ color:C.text }}>{typeof latestW==="number"?latestW.toFixed(1):latestW} กก.</b></div>
        </div>
        {goalProjection ? (
          <div style={{ background:C.orangeLight, borderRadius:12, padding:"12px 14px", display:"flex", flexDirection:"column", gap:6 }}>
            <div style={{ fontSize:13, color:C.text }}>
              ต้องเพิ่มอีก <b>{goalProjection.remaining>0?goalProjection.remaining.toFixed(1):0} กก.</b> · แนวโน้มปัจจุบัน <b>{goalProjection.weeklyRate>=0?"+":""}{goalProjection.weeklyRate.toFixed(2)} กก./สัปดาห์</b>
            </div>
            <div style={{ fontSize:13, color:C.text }}>
              {goalProjection.projectedDate
                ? <>คาดว่าจะถึงเป้าหมายประมาณ <b>{goalProjection.projectedDate}</b> ({Math.round(goalProjection.daysNeeded)} วัน)</>
                : <>ยังไม่มีแนวโน้มน้ำหนักเพิ่มขึ้นชัดเจนจากข้อมูลปัจจุบัน จึงยังประเมินวันที่ไม่ได้</>}
            </div>
            <div style={{ fontSize:12, color:C.gray }}>ความมั่นใจของการประเมิน: <b style={{ color: goalProjection.confidence==="สูง"?C.green:goalProjection.confidence==="ปานกลาง"?C.orange:C.red }}>{goalProjection.confidence}</b> (คำนวณจากความสม่ำเสมอของแนวโน้มน้ำหนักย้อนหลัง)</div>
          </div>
        ) : (
          <div style={{ fontSize:13, color:C.gray, textAlign:"center", padding:"12px 0" }}>ต้องมีข้อมูลน้ำหนักอย่างน้อย 2 ครั้งเพื่อประเมินแนวโน้ม</div>
        )}
      </Card>

      {/* Edit cat profile modal (separate from appointment) */}
      {editCat && (
        <Modal title="แก้ไขข้อมูลสมจ๋อง" onClose={()=>setEditCat(false)}>
          {[["name","ชื่อแมว"],["breed","สายพันธุ์"],["bday","วันเกิด"],["motto","คำขวัญ"]].map(([k,l])=>(
            <Field key={k} label={l} value={form[k]||""} onChange={v=>setForm(p=>({...p,[k]:v}))} type={k==="bday"?"date":"text"}/>
          ))}
          <Field label="เพศ" value={form.sex} onChange={v=>setForm(p=>({...p,sex:v}))} options={["ชาย","หญิง"]}/>
          <div style={{ display:"flex", gap:8, marginTop:4 }}>
            <Btn label="บันทึก" onClick={saveEdit}/>
            <Btn label="ยกเลิก" onClick={()=>setEditCat(false)} outline/>
          </div>
        </Modal>
      )}

      {/* Edit appointment modal (separate from profile) */}
      {editAppt && (
        <Modal title="แก้ไขนัดหมอ" onClose={()=>setEditAppt(false)}>
          <Field label="วันนัดครั้งต่อไป" value={apptForm.nextAppt||""} onChange={v=>setApptForm(p=>({...p,nextAppt:v}))} type="date"/>
          <Field label="โรงพยาบาล" value={apptForm.hospital||""} onChange={v=>setApptForm(p=>({...p,hospital:v}))}/>
          <Field label="สัตวแพทย์" value={apptForm.vet||""} onChange={v=>setApptForm(p=>({...p,vet:v}))}/>
          <div style={{ display:"flex", gap:8, marginTop:4 }}>
            <Btn label="บันทึก" onClick={saveAppt}/>
            <Btn label="ยกเลิก" onClick={()=>setEditAppt(false)} outline/>
          </div>
        </Modal>
      )}

      {/* Edit target weight modal */}
      {editTarget && (
        <Modal title="ตั้งเป้าหมายน้ำหนัก" onClose={()=>setEditTarget(false)}>
          <Field label="น้ำหนักเป้าหมาย (กก.)" value={targetForm} onChange={setTargetForm} type="number"/>
          <div style={{ display:"flex", gap:8, marginTop:4 }}>
            <Btn label="บันทึก" onClick={saveTarget}/>
            <Btn label="ยกเลิก" onClick={()=>setEditTarget(false)} outline/>
          </div>
        </Modal>
      )}

      {/* Edit weight modal */}
      {editWeight && (
        <Modal title={editWeight==="new"?"เพิ่มน้ำหนัก":"แก้ไขน้ำหนัก"} onClose={()=>setEditWeight(null)}>
          <Field label="วันที่" value={wForm.date} onChange={v=>setWForm(p=>({...p,date:v}))} type="date"/>
          <div style={{ marginBottom:12 }}>
            <div style={{ fontSize:12, color:C.gray, fontWeight:600, marginBottom:4 }}>หน่วย</div>
            <div style={{ display:"flex", gap:8 }}>
              {[["kg","กิโลกรัม"],["g","กรัม"]].map(([u,l])=>(
                <button type="button" key={u} onClick={()=>changeWUnit(u)} style={{ padding:"6px 14px", borderRadius:99, border:"1.5px solid", borderColor:wUnit===u?C.orange:"#E5E7EB", background:wUnit===u?C.orangeLight:"#fff", color:wUnit===u?C.orange:C.gray, fontWeight:600, fontSize:13, cursor:"pointer" }}>{l}</button>
              ))}
            </div>
          </div>
          <Field label={wUnit==="g"?"น้ำหนัก (กรัม)":"น้ำหนัก (กก.)"} value={wForm.w} onChange={v=>setWForm(p=>({...p,w:v}))} type="number"/>
          <div style={{ display:"flex", gap:8, marginTop:4 }}>
            <Btn label="บันทึก" onClick={saveWeight}/>
            <Btn label="ยกเลิก" onClick={()=>setEditWeight(null)} outline/>
          </div>
        </Modal>
      )}
    </div>
  );
}

// ─────────────────────────────────────────────────────────────────────
// Medical Timeline
// ─────────────────────────────────────────────────────────────────────
function Medical({ timeline, setTimeline }) {
  const [selectedId, setSelectedId]=useState(null);
  const [editing, setEditing]=useState(null);
  const [form, setForm]=useState(EMPTY_TL);
  const [confirm, setConfirm]=useState(null);

  const openEdit=(t)=>{ setForm(t ? {...t} : {...EMPTY_TL, date:todayISO(), time:nowHHMM()}); setEditing(t ? t.id : "new"); };
  const closeEdit=()=>setEditing(null);

  const save=()=>{
    if(!form.diagnosis) return;
    if(editing==="new"){
      const created = {...form, id:Date.now()};
      setTimeline(p=>[created, ...p]);
    } else {
      const updated={...form, id:editing};
      setTimeline(p=>p.map(x=>x.id===editing ? updated : x));
    }
    setEditing(null);
  };

  const del=(id)=>setConfirm({ msg:"ลบรายการนี้?", fn:()=>{
    setTimeline(p=>p.filter(x=>x.id!==id));
    setConfirm(null);
    setSelectedId(null);
  }});

  // detail view - always derive fresh from the current timeline array
  const detailItem = selectedId!=null ? timeline.find(x=>x.id===selectedId) : null;

  return (
    <div style={{ display:"flex", flexDirection:"column", gap:12 }}>
      {confirm && <Confirm msg={confirm.msg} onConfirm={confirm.fn} onCancel={()=>setConfirm(null)}/>}

      {/* ── Modal always rendered at top level, never buried in a branch ── */}
      {editing && (
        <Modal title={editing==="new"?"เพิ่มรายการรักษา":"แก้ไขรายการรักษา"} onClose={closeEdit}>
          {[
            ["date","วันที่","date"],["time","เวลา","time"],
            ["hospital","โรงพยาบาล","text"],["vet","สัตวแพทย์","text"],
            ["diagnosis","การวินิจฉัย *","text"],["treatment","การรักษา","text"],
            ["cost","ค่าใช้จ่าย (฿)","number"],
          ].map(([k,l,tp])=>(
            <Field key={k} label={l} value={form[k]||""} onChange={v=>setForm(p=>({...p,[k]:v}))} type={tp}/>
          ))}
          <Field label="หมายเหตุ" value={form.note||""} onChange={v=>setForm(p=>({...p,note:v}))} rows={2}/>
          <Field label="Tags (คั่นด้วย ,)" value={form.tags||""} onChange={v=>setForm(p=>({...p,tags:v}))}/>
          <div style={{ display:"grid", gridTemplateColumns:"1fr 1fr", gap:10 }}>
            <FileInput label="📷 รูปถ่าย" value={form.photo||""} onChange={v=>setForm(p=>({...p,photo:v}))}/>
            <FileInput label="🧾 ใบเสร็จ" value={form.receipt||""} onChange={v=>setForm(p=>({...p,receipt:v}))}/>
          </div>
          <div style={{ display:"flex", gap:8, marginTop:4 }}>
            <Btn label="บันทึก" onClick={save}/>
            <Btn label="ยกเลิก" onClick={closeEdit} outline/>
          </div>
        </Modal>
      )}

      {/* ── Detail view ── */}
      {detailItem && !editing ? (
        <>
          <button type="button" onClick={()=>setSelectedId(null)} style={{ background:C.grayLight, border:"none", borderRadius:99, padding:"8px 16px", marginBottom:4, cursor:"pointer", fontWeight:600, alignSelf:"flex-start" }}>← กลับ</button>
          <Card>
            <div style={{ display:"flex", justifyContent:"space-between", alignItems:"flex-start", marginBottom:12 }}>
              <div style={{ display:"flex", gap:6, flexWrap:"wrap" }}>
                {detailItem.tags?.split(",").filter(Boolean).map(tag=><Badge key={tag} label={tag.trim()} color={C.orange}/>)}
              </div>
              <div style={{ display:"flex", gap:6 }}>
                <IconBtn icon="✏️" onClick={()=>openEdit(detailItem)} color={C.orange}/>
                <IconBtn icon="🗑️" onClick={()=>del(detailItem.id)} color={C.red}/>
              </div>
            </div>
            <div style={{ fontSize:20, fontWeight:800, marginBottom:4, color:C.text }}>{detailItem.diagnosis}</div>
            <div style={{ fontSize:13, color:C.gray, marginBottom:16 }}>{detailItem.date} · {detailItem.time} · {detailItem.hospital}</div>
            {[["🏥 โรงพยาบาล",detailItem.hospital],["👨‍⚕️ สัตวแพทย์",detailItem.vet],["💊 การรักษา",detailItem.treatment],["📝 หมายเหตุ",detailItem.note]].map(([l,v])=>v&&(
              <div key={l} style={{ marginBottom:12 }}>
                <div style={{ fontSize:12, color:C.gray, fontWeight:600 }}>{l}</div>
                <div style={{ fontSize:14, color:C.text }}>{v}</div>
              </div>
            ))}
            {(detailItem.photo || detailItem.receipt) && (
              <div style={{ display:"grid", gridTemplateColumns: detailItem.photo && detailItem.receipt ? "1fr 1fr" : "1fr", gap:10, marginBottom:16 }}>
                {detailItem.photo && (
                  <div>
                    <div style={{ fontSize:12, color:C.gray, fontWeight:600, marginBottom:4 }}>📷 รูปถ่าย</div>
                    <img src={detailItem.photo} alt="รูปถ่าย" style={{ width:"100%", maxHeight:180, objectFit:"cover", borderRadius:12, border:`1.5px solid #E5E7EB` }}/>
                  </div>
                )}
                {detailItem.receipt && (
                  <div>
                    <div style={{ fontSize:12, color:C.gray, fontWeight:600, marginBottom:4 }}>🧾 ใบเสร็จ</div>
                    <img src={detailItem.receipt} alt="ใบเสร็จ" style={{ width:"100%", maxHeight:180, objectFit:"cover", borderRadius:12, border:`1.5px solid #E5E7EB` }}/>
                  </div>
                )}
              </div>
            )}
            <div style={{ background:C.orangeLight, borderRadius:12, padding:"12px 16px", display:"flex", justifyContent:"space-between" }}>
              <span style={{ fontSize:13, color:C.orange, fontWeight:600 }}>ค่าใช้จ่าย</span>
              <span style={{ fontSize:22, fontWeight:800, color:C.orange }}>฿{Number(detailItem.cost||0).toLocaleString()}</span>
            </div>
          </Card>
        </>
      ) : !editing ? (
        /* ── List view ── */
        <>
          <SectionTitle icon="🏥" title="ประวัติการรักษา" onAdd={()=>openEdit(null)}/>
          {timeline.map((t,i)=>(
            <div key={t.id} style={{ display:"flex", gap:12 }}>
              <div style={{ display:"flex", flexDirection:"column", alignItems:"center", paddingTop:4 }}>
                <div style={{ width:36, height:36, borderRadius:"50%", background:i===0?C.orange:C.grayLight, display:"flex", alignItems:"center", justifyContent:"center", flexShrink:0, fontSize:16 }}>{i===0?"🏥":"📋"}</div>
                {i<timeline.length-1&&<div style={{ width:2, flex:1, background:"#E5E7EB", marginTop:4, minHeight:24 }}/>}
              </div>
              <Card style={{ flex:1, padding:14 }}>
                <div style={{ display:"flex", justifyContent:"space-between", alignItems:"flex-start" }}>
                  <div onClick={()=>setSelectedId(t.id)} style={{ flex:1, cursor:"pointer" }}>
                    <div style={{ fontSize:14, fontWeight:700, color:C.text }}>{t.diagnosis}</div>
                    <div style={{ fontSize:12, color:C.gray }}>{t.date} · {t.hospital}</div>
                    <div style={{ fontSize:12, color:C.gray }}>👨‍⚕️ {t.vet}</div>
                  </div>
                  <div style={{ display:"flex", flexDirection:"column", alignItems:"flex-end", gap:4 }}>
                    <div style={{ fontSize:16, fontWeight:700, color:C.orange }}>฿{Number(t.cost||0).toLocaleString()}</div>
                    <div style={{ display:"flex", gap:6 }}>
                      <IconBtn icon="✏️" onClick={()=>openEdit(t)} color={C.orange}/>
                      <IconBtn icon="🗑️" onClick={()=>del(t.id)} color={C.red}/>
                    </div>
                  </div>
                </div>
              </Card>
            </div>
          ))}
        </>
      ) : null}
    </div>
  );
}

// ─────────────────────────────────────────────────────────────────────
// Medication
// ─────────────────────────────────────────────────────────────────────
function Medication({ meds, setMeds }) {
  const [editing, setEditing]=useState(null);
  const [form, setForm]=useState(EMPTY_MED);
  const [log, setLog]=useState({});
  const [confirm, setConfirm]=useState(null);

  const openEdit=(m)=>{ setForm(m?{...m}:{...EMPTY_MED, start:todayISO()}); setEditing(m?m.id:"new"); };
  const save=()=>{
    if(!form.name) return;
    if(editing==="new") setMeds(p=>[...p,{...form,id:Date.now()}]);
    else setMeds(p=>p.map(x=>x.id===editing?{...form,id:editing}:x));
    setEditing(null);
  };
  const del=(id)=>setConfirm({ msg:"ลบยานี้?", fn:()=>{ setMeds(p=>p.filter(x=>x.id!==id)); setConfirm(null); }});
  const toggle=(medId,time)=>setLog(p=>({...p,[`${medId}-${time}`]:!p[`${medId}-${time}`]}));

  const times=["เช้า 07:00","เที่ยง 12:00","เย็น 19:00","ก่อนนอน 22:00"];

  return (
    <div style={{ display:"flex", flexDirection:"column", gap:16 }}>
      {confirm && <Confirm msg={confirm.msg} onConfirm={confirm.fn} onCancel={()=>setConfirm(null)}/>}

      <Card>
        <SectionTitle icon="💊" title="ยาปัจจุบัน" onAdd={()=>openEdit(null)}/>
        <div style={{ display:"flex", flexDirection:"column", gap:10 }}>
          {meds.map(med=>(
            <div key={med.id} style={{ background:(med.color||C.orange)+"15", borderRadius:14, padding:"12px 14px", borderLeft:`4px solid ${med.color||C.orange}` }}>
              <div style={{ display:"flex", justifyContent:"space-between", alignItems:"flex-start" }}>
                <div style={{ flex:1 }}>
                  <div style={{ fontWeight:700, fontSize:14, color:C.text }}>{med.name}</div>
                  <div style={{ fontSize:12, color:C.gray }}>{med.dose} {med.unit} · {med.withFood} · ทุก {med.freq} ชม.</div>
                  <div style={{ fontSize:11, color:C.gray }}>ถึง {med.end}</div>
                </div>
                <div style={{ display:"flex", gap:6, flexShrink:0 }}>
                  <IconBtn icon="✏️" onClick={()=>openEdit(med)} color={C.orange}/>
                  <IconBtn icon="🗑️" onClick={()=>del(med.id)} color={C.red}/>
                </div>
              </div>
            </div>
          ))}
          {meds.length===0 && <div style={{ textAlign:"center", color:C.gray, fontSize:13, padding:"20px 0" }}>ยังไม่มียา กด + เพิ่ม</div>}
        </div>
      </Card>

      <Card>
        <SectionTitle icon="🕐" title="Checklist วันนี้"/>
        {times.map(time=>(
          <div key={time} style={{ marginBottom:16 }}>
            <div style={{ fontSize:13, fontWeight:700, color:C.gray, marginBottom:6 }}>{time}</div>
            {meds.map(med=>{
              const key=`${med.id}-${time}`, done=!!log[key];
              return (
                <button type="button" key={med.id} onClick={()=>toggle(med.id,time)} style={{ display:"flex", alignItems:"center", gap:10, background:done?C.green+"15":C.grayLight, borderRadius:12, padding:"10px 14px", border:`1.5px solid ${done?C.green:"#E5E7EB"}`, cursor:"pointer", width:"100%", marginBottom:6 }}>
                  <div style={{ width:24, height:24, borderRadius:"50%", background:done?C.green:"#D1D5DB", display:"flex", alignItems:"center", justifyContent:"center", flexShrink:0 }}>
                    {done&&<span style={{ color:"#fff", fontSize:13, fontWeight:700 }}>✓</span>}
                  </div>
                  <div style={{ flex:1, textAlign:"left" }}>
                    <div style={{ fontSize:13, fontWeight:600, color:C.text }}>{med.name}</div>
                    <div style={{ fontSize:11, color:C.gray }}>{med.dose} {med.unit} · {med.withFood}</div>
                  </div>
                  <div style={{ width:10, height:10, borderRadius:"50%", background:med.color||C.orange }}/>
                </button>
              );
            })}
          </div>
        ))}
      </Card>

      {editing && (
        <Modal title={editing==="new"?"เพิ่มยา":"แก้ไขยา"} onClose={()=>setEditing(null)}>
          <Field label="ชื่อยา" value={form.name} onChange={v=>setForm(p=>({...p,name:v}))}/>
          <Field label="Dose" value={form.dose} onChange={v=>setForm(p=>({...p,dose:v}))} type="number"/>
          <Field label="หน่วย" value={form.unit} onChange={v=>setForm(p=>({...p,unit:v}))} options={["mg","ml","cc","เม็ด","หลอด","หยด"]}/>
          <Field label="ทุกกี่ชั่วโมง" value={form.freq} onChange={v=>setForm(p=>({...p,freq:v}))} type="number"/>
          <Field label="เวลาที่ให้ยา" value={form.withFood} onChange={v=>setForm(p=>({...p,withFood:v}))} options={["ก่อนอาหาร","หลังอาหาร","พร้อมอาหาร"]}/>
          <Field label="วันที่เริ่ม" value={form.start} onChange={v=>setForm(p=>({...p,start:v}))} type="date"/>
          <Field label="วันที่สิ้นสุด" value={form.end} onChange={v=>setForm(p=>({...p,end:v}))} type="date"/>
          <div style={{ display:"flex", gap:8, marginTop:4 }}>
            <Btn label="บันทึก" onClick={save}/>
            <Btn label="ยกเลิก" onClick={()=>setEditing(null)} outline/>
          </div>
        </Modal>
      )}
    </div>
  );
}

// ─────────────────────────────────────────────────────────────────────
// Food & Water
// ─────────────────────────────────────────────────────────────────────
function FoodWater({ water, setWater, food, setFood }) {
  const [editW, setEditW]=useState(null);
  const [editF, setEditF]=useState(null);
  const [wForm, setWForm]=useState(EMPTY_WTR);
  const [fForm, setFForm]=useState(EMPTY_FOOD);
  const [confirm, setConfirm]=useState(null);
  const [cg, setCg]=useState(50);
  const [density, setDensity]=useState(1.0);

  const waterMl=water.filter(x=>x.done).reduce((s,w)=>s+Number(w.ml),0);
  const waterGoal=water.reduce((s,w)=>s+Number(w.ml),0);
  const waterPct=waterGoal?Math.min(100,Math.round((waterMl/waterGoal)*100)):0;

  const saveW=()=>{
    if(!wForm.time||!wForm.ml) return;
    if(editW==="new") setWater(p=>[...p,{id:Date.now(),...wForm,done:false}]);
    else setWater(p=>p.map(x=>x.id===editW?{...x,...wForm}:x));
    setEditW(null);
  };
  const delW=(id)=>setConfirm({ msg:"ลบรอบน้ำนี้?", fn:()=>{ setWater(p=>p.filter(x=>x.id!==id)); setConfirm(null); }});

  const saveF=()=>{
    if(!fForm.time) return;
    if(editF==="new") setFood(p=>[...p,{id:Date.now(),...fForm}]);
    else setFood(p=>p.map(x=>x.id===editF?{...x,...fForm}:x));
    setEditF(null);
  };
  const delF=(id)=>setConfirm({ msg:"ลบมื้ออาหารนี้?", fn:()=>{ setFood(p=>p.filter(x=>x.id!==id)); setConfirm(null); }});

  return (
    <div style={{ display:"flex", flexDirection:"column", gap:16 }}>
      {confirm && <Confirm msg={confirm.msg} onConfirm={confirm.fn} onCancel={()=>setConfirm(null)}/>}

      {/* Water */}
      <Card>
        <SectionTitle icon="💧" title="น้ำวันนี้" onAdd={()=>{ setWForm(EMPTY_WTR); setEditW("new"); }}/>
        <div style={{ display:"flex", alignItems:"center", gap:16, marginBottom:12 }}>
          <ProgressRing pct={waterPct} size={80} label={`${waterMl}`} sublabel="ml" color={C.blue} stroke={10}/>
          <div>
            <div style={{ fontSize:13, color:C.gray }}>เป้าหมาย {waterGoal} ml / วัน</div>
            <div style={{ fontSize:13, color:waterMl>=waterGoal?C.green:C.orange, fontWeight:600 }}>
              {waterMl>=waterGoal?"✅ ครบแล้ว!":` ขาดอีก ${waterGoal-waterMl} ml`}
            </div>
          </div>
        </div>
        {water.map(w=>(
          <div key={w.id} style={{ display:"flex", alignItems:"center", gap:8, marginBottom:8 }}>
            <button type="button" onClick={()=>setWater(p=>p.map(x=>x.id===w.id?{...x,done:!x.done}:x))}
              style={{ flex:1, display:"flex", alignItems:"center", gap:10, background:w.done?C.blue+"18":C.grayLight, borderRadius:12, padding:"10px 14px", border:`1.5px solid ${w.done?C.blue:"#E5E7EB"}`, cursor:"pointer" }}>
              <span style={{ fontSize:18 }}>💧</span>
              <div style={{ flex:1, textAlign:"left" }}>
                <div style={{ fontWeight:600, fontSize:13, color:C.text }}>{w.time}</div>
                <div style={{ fontSize:12, color:C.gray }}>{w.ml} ml</div>
              </div>
              <div style={{ width:24, height:24, borderRadius:"50%", background:w.done?C.blue:"#D1D5DB", display:"flex", alignItems:"center", justifyContent:"center" }}>
                {w.done&&<span style={{ color:"#fff", fontSize:13 }}>✓</span>}
              </div>
            </button>
            <IconBtn icon="✏️" onClick={()=>{ setWForm({time:w.time,ml:String(w.ml)}); setEditW(w.id); }} color={C.orange}/>
            <IconBtn icon="🗑️" onClick={()=>delW(w.id)} color={C.red}/>
          </div>
        ))}
      </Card>

      {/* Food */}
      <Card>
        <SectionTitle icon="🥣" title="อาหารวันนี้" onAdd={()=>{ setFForm(EMPTY_FOOD); setEditF("new"); }}/>
        {food.map(f=>(
          <div key={f.id} style={{ display:"flex", alignItems:"center", gap:8, marginBottom:8 }}>
            <button type="button" onClick={()=>setFood(p=>p.map(x=>x.id===f.id?{...x,done:!x.done}:x))}
              style={{ flex:1, display:"flex", alignItems:"center", gap:10, background:f.done?C.green+"15":C.grayLight, borderRadius:12, padding:"10px 14px", border:`1.5px solid ${f.done?C.green:"#E5E7EB"}`, cursor:"pointer" }}>
              <span style={{ fontSize:18 }}>🥣</span>
              <div style={{ flex:1, textAlign:"left" }}>
                <div style={{ fontWeight:600, fontSize:13, color:C.text }}>{f.label} {f.time}</div>
                <div style={{ fontSize:12, color:C.gray }}>{f.amount} {f.unit} · {f.brand}</div>
              </div>
              <div style={{ width:24, height:24, borderRadius:"50%", background:f.done?C.green:"#D1D5DB", display:"flex", alignItems:"center", justifyContent:"center" }}>
                {f.done&&<span style={{ color:"#fff", fontSize:13 }}>✓</span>}
              </div>
            </button>
            <IconBtn icon="✏️" onClick={()=>{ setFForm({time:f.time,label:f.label,amount:f.amount,unit:f.unit,brand:f.brand,done:f.done}); setEditF(f.id); }} color={C.orange}/>
            <IconBtn icon="🗑️" onClick={()=>delF(f.id)} color={C.red}/>
          </div>
        ))}
      </Card>

      {/* Converter */}
      <Card>
        <SectionTitle icon="⚗️" title="Food Converter"/>
        <div style={{ marginBottom:12 }}>
          <div style={{ fontSize:12, color:C.gray, marginBottom:4 }}>Density (g→ml)</div>
          <div style={{ display:"flex", gap:8 }}>
            {[0.85,0.90,0.95,1.00].map(d=>(
              <button type="button" key={d} onClick={()=>setDensity(d)} style={{ padding:"6px 12px", borderRadius:99, border:"1.5px solid", borderColor:density===d?C.orange:"#E5E7EB", background:density===d?C.orangeLight:"#fff", color:density===d?C.orange:C.gray, fontWeight:600, fontSize:13, cursor:"pointer" }}>{d}</button>
            ))}
          </div>
        </div>
        <Field label="กรัม (g)" value={String(cg)} onChange={v=>setCg(Number(v))} type="number"/>
        <div style={{ display:"grid", gridTemplateColumns:"1fr 1fr", gap:10 }}>
          {[["ml",(cg*density).toFixed(1)],["cc",(cg*density).toFixed(1)]].map(([u,v])=>(
            <div key={u} style={{ background:C.blueLight, borderRadius:12, padding:"12px 14px", textAlign:"center" }}>
              <div style={{ fontSize:22, fontWeight:800, color:C.blue }}>{v}</div>
              <div style={{ fontSize:12, color:C.gray }}>{u}</div>
            </div>
          ))}
        </div>
      </Card>

      {/* Edit Water Modal */}
      {editW && (
        <Modal title={editW==="new"?"เพิ่มรอบน้ำ":"แก้ไขรอบน้ำ"} onClose={()=>setEditW(null)}>
          <Field label="เวลา (HH:MM)" value={wForm.time} onChange={v=>setWForm(p=>({...p,time:v}))} type="time"/>
          <Field label="ปริมาณ (ml)" value={wForm.ml} onChange={v=>setWForm(p=>({...p,ml:v}))} type="number"/>
          <div style={{ display:"flex", gap:8, marginTop:4 }}>
            <Btn label="บันทึก" onClick={saveW}/><Btn label="ยกเลิก" onClick={()=>setEditW(null)} outline/>
          </div>
        </Modal>
      )}

      {/* Edit Food Modal */}
      {editF && (
        <Modal title={editF==="new"?"เพิ่มมื้ออาหาร":"แก้ไขมื้ออาหาร"} onClose={()=>setEditF(null)}>
          <Field label="เวลา (HH:MM)" value={fForm.time} onChange={v=>setFForm(p=>({...p,time:v}))} type="time"/>
          <Field label="ชื่อมื้อ (เช่น เช้า)" value={fForm.label} onChange={v=>setFForm(p=>({...p,label:v}))}/>
          <Field label="ปริมาณ (เช่น ½)" value={fForm.amount} onChange={v=>setFForm(p=>({...p,amount:v}))}/>
          <Field label="หน่วย" value={fForm.unit} onChange={v=>setFForm(p=>({...p,unit:v}))} options={["ซอง","กรัม","ml","cc"]}/>
          <Field label="ยี่ห้ออาหาร" value={fForm.brand} onChange={v=>setFForm(p=>({...p,brand:v}))}/>
          <div style={{ display:"flex", gap:8, marginTop:4 }}>
            <Btn label="บันทึก" onClick={saveF}/><Btn label="ยกเลิก" onClick={()=>setEditF(null)} outline/>
          </div>
        </Modal>
      )}
    </div>
  );
}

// ─────────────────────────────────────────────────────────────────────
// Expense (read-only display)
// ─────────────────────────────────────────────────────────────────────
function Expense() {
  return (
    <div style={{ display:"flex", flexDirection:"column", gap:16 }}>
      <Card>
        <div style={{ textAlign:"center", marginBottom:16 }}>
          <div style={{ fontSize:13, color:C.gray }}>ค่าใช้จ่ายทั้งหมด</div>
          <div style={{ fontSize:32, fontWeight:800, color:C.orange }}>฿{totalExp.toLocaleString()}</div>
        </div>
        <ResponsiveContainer width="100%" height={180}>
          <PieChart>
            <Pie data={EXPENSE_DATA} dataKey="amount" cx="50%" cy="50%" outerRadius={70} label={({percent})=>`${(percent*100).toFixed(0)}%`} labelLine={false}>
              {EXPENSE_DATA.map((e,i)=><Cell key={i} fill={e.color}/>)}
            </Pie>
            <Tooltip formatter={v=>`฿${v.toLocaleString()}`}/>
          </PieChart>
        </ResponsiveContainer>
        {EXPENSE_DATA.map(e=>(
          <div key={e.cat} style={{ display:"flex", alignItems:"center", gap:8, marginBottom:6 }}>
            <div style={{ width:12, height:12, borderRadius:"50%", background:e.color, flexShrink:0 }}/>
            <div style={{ flex:1, fontSize:13, color:C.text }}>{e.cat}</div>
            <div style={{ fontSize:13, fontWeight:600 }}>฿{e.amount.toLocaleString()}</div>
          </div>
        ))}
      </Card>
      <Card>
        <SectionTitle icon="📊" title="รายจ่ายรายเดือน"/>
        <ResponsiveContainer width="100%" height={160}>
          <BarChart data={MONTHLY}>
            <CartesianGrid strokeDasharray="3 3" stroke="#F3F4F6"/>
            <XAxis dataKey="month" tick={{ fontSize:11 }}/><YAxis tick={{ fontSize:11 }} tickFormatter={v=>`${(v/1000).toFixed(0)}k`}/>
            <Tooltip formatter={v=>`฿${v.toLocaleString()}`}/>
            <Bar dataKey="total" fill={C.orange} radius={[6,6,0,0]}/>
          </BarChart>
        </ResponsiveContainer>
      </Card>
    </div>
  );
}

// ─────────────────────────────────────────────────────────────────────
// Hospital & Stock
// ─────────────────────────────────────────────────────────────────────
function HospitalStock({ hospitals, setHospitals, stock, setStock }) {
  const [editH, setEditH]=useState(null);
  const [hForm, setHForm]=useState(EMPTY_HSP);
  const [editS, setEditS]=useState(null);
  const [sForm, setSForm]=useState(EMPTY_STK);
  const [confirm, setConfirm]=useState(null);

  const saveH=()=>{
    if(!hForm.name) return;
    if(editH==="new") setHospitals(p=>[...p,{id:Date.now(),...hForm}]);
    else setHospitals(p=>p.map(x=>x.id===editH?{...hForm,id:editH}:x));
    setEditH(null);
  };
  const delH=(id)=>setConfirm({ msg:"ลบโรงพยาบาลนี้?", fn:()=>{ setHospitals(p=>p.filter(x=>x.id!==id)); setConfirm(null); }});

  const saveS=()=>{
    if(!sForm.name) return;
    if(editS==="new") setStock(p=>[...p,{id:Date.now(),...sForm}]);
    else setStock(p=>p.map(x=>x.id===editS?{...sForm,id:editS}:x));
    setEditS(null);
  };
  const delS=(id)=>setConfirm({ msg:"ลบสต็อกนี้?", fn:()=>{ setStock(p=>p.filter(x=>x.id!==id)); setConfirm(null); }});
  const adjustQty=(id,delta)=>setStock(p=>p.map(x=>x.id===id?{...x,qty:String(Math.max(0,Number(x.qty)+delta))}:x));

  return (
    <div style={{ display:"flex", flexDirection:"column", gap:16 }}>
      {confirm && <Confirm msg={confirm.msg} onConfirm={confirm.fn} onCancel={()=>setConfirm(null)}/>}

      {/* Hospitals */}
      <SectionTitle icon="🏥" title="โรงพยาบาล" onAdd={()=>{ setHForm(EMPTY_HSP); setEditH("new"); }}/>
      {hospitals.map(h=>(
        <Card key={h.id}>
          <div style={{ display:"flex", justifyContent:"space-between", alignItems:"flex-start", marginBottom:8 }}>
            <div style={{ fontWeight:700, fontSize:15, color:C.text, flex:1 }}>{h.name}</div>
            <div style={{ display:"flex", gap:6 }}>
              <IconBtn icon="✏️" onClick={()=>{ setHForm({name:h.name,phone:h.phone,mapUrl:h.mapUrl,vets:h.vets}); setEditH(h.id); }} color={C.orange}/>
              <IconBtn icon="🗑️" onClick={()=>delH(h.id)} color={C.red}/>
            </div>
          </div>
          <div style={{ display:"flex", gap:8, marginBottom:8 }}>
            <a href={`tel:${h.phone}`} style={{ flex:1, background:C.green+"18", color:C.green, borderRadius:12, padding:"10px 0", textAlign:"center", textDecoration:"none", fontWeight:600, fontSize:13 }}>📞 {h.phone}</a>
            <a href={h.mapUrl} target="_blank" rel="noreferrer" style={{ flex:1, background:C.blue+"18", color:C.blue, borderRadius:12, padding:"10px 0", textAlign:"center", textDecoration:"none", fontWeight:600, fontSize:13 }}>🗺️ แผนที่</a>
          </div>
          <div style={{ fontSize:12, color:C.gray }}>👨‍⚕️ {h.vets}</div>
        </Card>
      ))}

      {/* Emergency */}
      <Card style={{ background:"#FFF0F0", border:`2px solid ${C.red}` }}>
        <div style={{ fontWeight:700, fontSize:15, color:C.red, marginBottom:12 }}>🚨 ฉุกเฉิน</div>
        {hospitals.map(h=>(
          <a key={h.id} href={`tel:${h.phone}`} style={{ display:"flex", alignItems:"center", gap:10, background:C.orange+"15", borderRadius:12, padding:"12px 14px", marginBottom:8, textDecoration:"none" }}>
            <span style={{ fontSize:20 }}>📞</span>
            <span style={{ fontWeight:600, fontSize:13, color:C.orange }}>โทร {h.name}</span>
            <span style={{ fontSize:13, color:C.gray, marginLeft:"auto" }}>{h.phone}</span>
          </a>
        ))}
      </Card>

      {/* Stock */}
      <SectionTitle icon="📦" title="สต็อก" onAdd={()=>{ setSForm(EMPTY_STK); setEditS("new"); }}/>
      {stock.map(s=>{
        const pct=Math.round((Number(s.qty)/(Number(s.min)*2.5))*100);
        const low=Number(s.qty)<=Number(s.min);
        return (
          <Card key={s.id} style={{ padding:"12px 14px" }}>
            <div style={{ display:"flex", justifyContent:"space-between", alignItems:"flex-start", marginBottom:6 }}>
              <div style={{ flex:1 }}>
                <div style={{ fontSize:13, fontWeight:700, color:C.text }}>{s.name}</div>
                <div style={{ fontSize:11, color:C.gray }}>{s.cat} · ขั้นต่ำ {s.min} {s.unit}</div>
              </div>
              <div style={{ display:"flex", flexDirection:"column", alignItems:"flex-end", gap:4 }}>
                {low && <Badge label="ใกล้หมด!" color={C.red}/>}
                <div style={{ display:"flex", gap:4 }}>
                  <IconBtn icon="✏️" onClick={()=>{ setSForm({cat:s.cat,name:s.name,qty:s.qty,unit:s.unit,min:s.min,price:s.price}); setEditS(s.id); }} color={C.orange}/>
                  <IconBtn icon="🗑️" onClick={()=>delS(s.id)} color={C.red}/>
                </div>
              </div>
            </div>
            <div style={{ display:"flex", alignItems:"center", gap:8, marginBottom:6 }}>
              <button type="button" onClick={()=>adjustQty(s.id,-1)} style={{ width:28,height:28,borderRadius:"50%",background:C.grayLight,border:"none",cursor:"pointer",fontSize:16,fontWeight:700,display:"flex",alignItems:"center",justifyContent:"center" }}>−</button>
              <div style={{ flex:1 }}>
                <div style={{ height:6, borderRadius:99, background:"#E5E7EB", overflow:"hidden" }}>
                  <div style={{ width:`${Math.min(100,pct)}%`, height:"100%", background:low?C.red:C.green, borderRadius:99 }}/>
                </div>
              </div>
              <span style={{ fontSize:15, fontWeight:700, color:low?C.red:C.text, minWidth:50, textAlign:"center" }}>{s.qty} {s.unit}</span>
              <button type="button" onClick={()=>adjustQty(s.id,1)} style={{ width:28,height:28,borderRadius:"50%",background:C.orangeLight,border:"none",cursor:"pointer",fontSize:16,fontWeight:700,color:C.orange,display:"flex",alignItems:"center",justifyContent:"center" }}>+</button>
            </div>
          </Card>
        );
      })}

      {/* Hospital modal */}
      {editH && (
        <Modal title={editH==="new"?"เพิ่มโรงพยาบาล":"แก้ไขโรงพยาบาล"} onClose={()=>setEditH(null)}>
          <Field label="ชื่อโรงพยาบาล" value={hForm.name} onChange={v=>setHForm(p=>({...p,name:v}))}/>
          <Field label="เบอร์โทร" value={hForm.phone} onChange={v=>setHForm(p=>({...p,phone:v}))} type="tel"/>
          <Field label="Google Maps URL" value={hForm.mapUrl} onChange={v=>setHForm(p=>({...p,mapUrl:v}))}/>
          <Field label="สัตวแพทย์ (คั่นด้วย ,)" value={hForm.vets} onChange={v=>setHForm(p=>({...p,vets:v}))}/>
          <div style={{ display:"flex", gap:8, marginTop:4 }}>
            <Btn label="บันทึก" onClick={saveH}/><Btn label="ยกเลิก" onClick={()=>setEditH(null)} outline/>
          </div>
        </Modal>
      )}

      {/* Stock modal */}
      {editS && (
        <Modal title={editS==="new"?"เพิ่มสต็อก":"แก้ไขสต็อก"} onClose={()=>setEditS(null)}>
          <Field label="หมวดหมู่" value={sForm.cat} onChange={v=>setSForm(p=>({...p,cat:v}))} options={["อาหารเปียก","อาหารแห้ง","ยา","อุปกรณ์","อื่น ๆ"]}/>
          <Field label="ชื่อสินค้า" value={sForm.name} onChange={v=>setSForm(p=>({...p,name:v}))}/>
          <Field label="จำนวน" value={sForm.qty} onChange={v=>setSForm(p=>({...p,qty:v}))} type="number"/>
          <Field label="หน่วย" value={sForm.unit} onChange={v=>setSForm(p=>({...p,unit:v}))}/>
          <Field label="ขั้นต่ำ" value={sForm.min} onChange={v=>setSForm(p=>({...p,min:v}))} type="number"/>
          <Field label="ราคา/ชิ้น (฿)" value={sForm.price} onChange={v=>setSForm(p=>({...p,price:v}))} type="number"/>
          <div style={{ display:"flex", gap:8, marginTop:4 }}>
            <Btn label="บันทึก" onClick={saveS}/><Btn label="ยกเลิก" onClick={()=>setEditS(null)} outline/>
          </div>
        </Modal>
      )}
    </div>
  );
}

// ─────────────────────────────────────────────────────────────────────
// AI Assistant
// ─────────────────────────────────────────────────────────────────────
function AIAssistant({ cat, water, food, meds, stock }) {
  const [messages, setMessages]=useState([{ role:"assistant", content:`สวัสดีครับ! ผมช่วยดูแล${cat.name}ได้เลย 🐱\nถามได้ทุกเรื่อง — ยา น้ำ อาหาร ค่าใช้จ่าย หรือสถานะสุขภาพวันนี้` }]);
  const [input, setInput]=useState("");
  const [loading, setLoading]=useState(false);
  const bottomRef=useRef(null);

  const SUGG=["วันนี้กินน้ำครบไหม?","เดือนนี้ค่ารักษาเท่าไร?","ยาตัวไหนกำลังจะหมด?","สรุปสุขภาพวันนี้","สต็อกอะไรใกล้หมดบ้าง?"];

  const waterDone=water.filter(w=>w.done).length;
  const waterMl=water.filter(w=>w.done).reduce((s,w)=>s+Number(w.ml),0);
  const waterGoal=water.reduce((s,w)=>s+Number(w.ml),0);
  const foodDone=food.filter(f=>f.done).length;
  const lowStock=stock.filter(s=>Number(s.qty)<=Number(s.min));

  const SYSTEM=`คุณคือ AI ผู้ช่วยดูแลสุขภาพแมว ชื่อ${cat.name} สายพันธุ์ ${cat.breed} เพศ${cat.sex}
ข้อมูลปัจจุบัน:
- น้ำหนักล่าสุด: ${cat.weight} กก.
- น้ำวันนี้: ${waterMl} ml จากเป้า ${waterGoal} ml (${waterDone}/${water.length} รอบ)
- อาหารวันนี้: ${foodDone}/${food.length} มื้อ
- ยาที่ใช้: ${meds.map(m=>`${m.name} ${m.dose}${m.unit} ทุก ${m.freq}ชม.`).join(", ")||"ไม่มี"}
- สต็อกใกล้หมด: ${lowStock.length ? lowStock.map(s=>`${s.name} (${s.qty} ${s.unit})`).join(", ") : "ไม่มี"}
- นัดหมอ: ${cat.nextAppt} ที่ ${cat.hospital}
ตอบภาษาไทย กระชับ ใจดี มี emoji เล็กน้อย`;

  const send=async(text)=>{
    const msg=text||input.trim(); if(!msg||loading) return;
    setInput(""); setMessages(p=>[...p,{role:"user",content:msg}]); setLoading(true);
    try {
      const res=await fetch("https://api.anthropic.com/v1/messages",{ method:"POST", headers:{"Content-Type":"application/json"},
        body:JSON.stringify({ model:"claude-sonnet-4-6", max_tokens:1000, system:SYSTEM,
          messages:[...messages.filter(m=>m.role!=="system").map(m=>({role:m.role,content:m.content})),{role:"user",content:msg}] })
      });
      const data=await res.json();
      setMessages(p=>[...p,{role:"assistant",content:data.content?.[0]?.text||"ขอโทษครับ ตอบไม่ได้ตอนนี้"}]);
    } catch { setMessages(p=>[...p,{role:"assistant",content:"❌ เกิดข้อผิดพลาด กรุณาลองใหม่"}]); }
    setLoading(false);
  };

  useEffect(()=>{ bottomRef.current?.scrollIntoView({behavior:"smooth"}); },[messages,loading]);

  return (
    <div style={{ display:"flex", flexDirection:"column", height:"calc(100vh - 180px)", minHeight:400 }}>
      <div style={{ flex:1, overflowY:"auto", display:"flex", flexDirection:"column", gap:12, paddingBottom:12 }}>
        {messages.map((m,i)=>(
          <div key={i} style={{ display:"flex", justifyContent:m.role==="user"?"flex-end":"flex-start" }}>
            {m.role==="assistant" && <div style={{ fontSize:26, marginRight:8, alignSelf:"flex-end" }}>🐱</div>}
            <div style={{ maxWidth:"78%", background:m.role==="user"?C.orange:C.card, color:m.role==="user"?"#fff":C.text,
              borderRadius:m.role==="user"?"18px 18px 4px 18px":"18px 18px 18px 4px", padding:"10px 14px", fontSize:13, lineHeight:1.6,
              boxShadow:"0 1px 8px rgba(0,0,0,0.08)", whiteSpace:"pre-wrap" }}>{m.content}</div>
          </div>
        ))}
        {loading && (
          <div style={{ display:"flex", alignItems:"flex-end", gap:8 }}>
            <div style={{ fontSize:26 }}>🐱</div>
            <div style={{ background:C.card, borderRadius:"18px 18px 18px 4px", padding:"12px 16px", boxShadow:"0 1px 8px rgba(0,0,0,0.08)" }}>
              <div style={{ display:"flex", gap:4 }}>
                {[0,1,2].map(d=><div key={d} style={{ width:8,height:8,borderRadius:"50%",background:C.orange,animation:`bounce 1s ${d*0.2}s infinite` }}/>)}
              </div>
            </div>
          </div>
        )}
        <div ref={bottomRef}/>
      </div>
      {messages.length<=2 && (
        <div style={{ display:"flex", gap:6, flexWrap:"wrap", marginBottom:10 }}>
          {SUGG.map(s=>(
            <button type="button" key={s} onClick={()=>send(s)} style={{ background:C.orangeLight, color:C.orange, border:"none", borderRadius:99, padding:"6px 12px", fontSize:12, fontWeight:600, cursor:"pointer" }}>{s}</button>
          ))}
        </div>
      )}
      <div style={{ display:"flex", gap:8 }}>
        <input value={input} onChange={e=>setInput(e.target.value)} onKeyDown={e=>e.key==="Enter"&&send()}
          placeholder={`ถามเกี่ยวกับ${cat.name}...`}
          style={{ flex:1, border:`1.5px solid #E5E7EB`, borderRadius:14, padding:"10px 14px", fontSize:13, outline:"none", fontFamily:"inherit" }}/>
        <button type="button" onClick={()=>send()} disabled={loading||!input.trim()} style={{ background:C.orange, color:"#fff", border:"none", borderRadius:14, padding:"10px 18px", fontWeight:700, cursor:"pointer", opacity:(loading||!input.trim())?0.5:1 }}>ส่ง</button>
      </div>
      <style>{`@keyframes bounce{0%,100%{transform:translateY(0)}50%{transform:translateY(-6px)}}`}</style>
    </div>
  );
}

// ─────────────────────────────────────────────────────────────────────
// App Shell
// ─────────────────────────────────────────────────────────────────────
const TABS=[
  { id:"home",icon:"🏠",label:"หน้าแรก" },{ id:"medical",icon:"🏥",label:"ประวัติ" },
  { id:"meds",icon:"💊",label:"ยา" },{ id:"food",icon:"🥣",label:"อาหาร/น้ำ" },
  { id:"expense",icon:"💰",label:"ค่าใช้จ่าย" },{ id:"hosp",icon:"📦",label:"รพ./สต็อก" },{ id:"ai",icon:"🤖",label:"AI" },
];

export default function App() {
  const [tab, setTab]=useState("home");
  const [cat, setCat]=useState(SEED_CAT);
  const [weights, setWeights]=useState(SEED_WEIGHTS);
  const [timeline, setTimeline]=useState(SEED_TL);
  const [meds, setMeds]=useState(SEED_MEDS);
  const [water, setWater]=useState(SEED_WATER);
  const [food, setFood]=useState(SEED_FOOD);
  const [hospitals, setHospitals]=useState(SEED_HOSPITALS);
  const [stock, setStock]=useState(SEED_STOCK);
  const [checklist, setChecklist]=useState(SEED_CHECK);
  const [showReset, setShowReset]=useState(false);

  const [syncStatus, setSyncStatus]=useState("connecting"); // connecting | live | offline
  const loadedRef = useRef(false);
  const skipNextSaveRef = useRef(false);
  const lastTsRef = useRef(0);
  const saveTimerRef = useRef(null);

  const applyRemotePayload = (p) => {
    if (!p) return;
    skipNextSaveRef.current = true;
    if (p.cat) setCat(p.cat);
    if (p.weights) setWeights(p.weights);
    if (p.timeline) setTimeline(p.timeline);
    if (p.meds) setMeds(p.meds);
    if (p.water) setWater(p.water);
    if (p.food) setFood(p.food);
    if (p.hospitals) setHospitals(p.hospitals);
    if (p.stock) setStock(p.stock);
    if (p.checklist) setChecklist(p.checklist);
  };

  const buildPayload = () => ({ cat, weights, timeline, meds, water, food, hospitals, stock, checklist });

  // ── Initial load from Supabase ──
  useEffect(() => {
    (async () => {
      try {
        const { data, error } = await supabase.from("app_state").select("*").eq("id", ROW_ID).maybeSingle();
        if (error) throw error;
        if (data && data.payload) {
          applyRemotePayload(data.payload);
          lastTsRef.current = data.updated_at ? new Date(data.updated_at).getTime() : Date.now();
        } else {
          // no shared record yet - create it with the current (seed) data
          const seedPayload = { cat:SEED_CAT, weights:SEED_WEIGHTS, timeline:SEED_TL, meds:SEED_MEDS, water:SEED_WATER, food:SEED_FOOD, hospitals:SEED_HOSPITALS, stock:SEED_STOCK, checklist:SEED_CHECK };
          const nowIso = new Date().toISOString();
          await supabase.from("app_state").upsert({ id:ROW_ID, payload:seedPayload, updated_at:nowIso });
          lastTsRef.current = new Date(nowIso).getTime();
        }
        setSyncStatus("live");
      } catch (e) {
        console.error("Supabase load failed, running in offline/local mode:", e);
        setSyncStatus("offline");
      } finally {
        loadedRef.current = true;
      }
    })();
  }, []);

  // ── Realtime: receive changes made by other people ──
  useEffect(() => {
    const channel = supabase
      .channel("app_state_changes")
      .on("postgres_changes", { event: "UPDATE", schema: "public", table: "app_state", filter: `id=eq.${ROW_ID}` }, (payload) => {
        const row = payload.new;
        if (!row) return;
        const ts = row.updated_at ? new Date(row.updated_at).getTime() : 0;
        if (ts <= lastTsRef.current) return; // our own write or an older event - ignore
        lastTsRef.current = ts;
        applyRemotePayload(row.payload);
      })
      .subscribe((status) => {
        if (status === "SUBSCRIBED") setSyncStatus((s)=> s==="offline" ? s : "live");
      });
    return () => { supabase.removeChannel(channel); };
  }, []);

  // ── Debounced save: push local changes up to Supabase for everyone else ──
  useEffect(() => {
    if (!loadedRef.current) return;
    if (skipNextSaveRef.current) { skipNextSaveRef.current = false; return; }
    if (saveTimerRef.current) clearTimeout(saveTimerRef.current);
    saveTimerRef.current = setTimeout(async () => {
      try {
        const nowIso = new Date().toISOString();
        const { data, error } = await supabase
          .from("app_state")
          .update({ payload: buildPayload(), updated_at: nowIso })
          .eq("id", ROW_ID)
          .select()
          .maybeSingle();
        if (error) throw error;
        lastTsRef.current = data?.updated_at ? new Date(data.updated_at).getTime() : new Date(nowIso).getTime();
        setSyncStatus("live");
      } catch (e) {
        console.error("Supabase save failed:", e);
        setSyncStatus("offline");
      }
    }, 600);
    return () => clearTimeout(saveTimerRef.current);
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [cat, weights, timeline, meds, water, food, hospitals, stock, checklist]);

  const resetAll = () => {
    setCat(SEED_CAT); setWeights(SEED_WEIGHTS); setTimeline(SEED_TL); setMeds(SEED_MEDS);
    setWater(SEED_WATER); setFood(SEED_FOOD); setHospitals(SEED_HOSPITALS); setStock(SEED_STOCK);
    setChecklist(SEED_CHECK); setShowReset(false);
  };

  return (
    <div style={{ background:C.cream, minHeight:"100vh", fontFamily:"'Noto Sans Thai','Sarabun',-apple-system,sans-serif", maxWidth:480, margin:"0 auto" }}>
      {/* Top bar */}
      <div style={{ position:"sticky", top:0, zIndex:200, background:"rgba(255,248,240,0.95)", backdropFilter:"blur(12px)", borderBottom:`1px solid #F3F4F6`, padding:"10px 16px", display:"flex", alignItems:"center", justifyContent:"space-between" }}>
        <div style={{ display:"flex", alignItems:"center", gap:8 }}>
          <span style={{ fontSize:22 }}>🐱</span>
          <div>
            <div style={{ fontWeight:800, fontSize:16, color:C.text, lineHeight:1.1 }}>{cat.name}</div>
            <div style={{ fontSize:10, color:C.gray }}>Health Tracker</div>
          </div>
        </div>
        <div style={{ display:"flex", alignItems:"center", gap:8 }}>
          <div style={{
              background: syncStatus==="live" ? C.green+"22" : syncStatus==="offline" ? C.red+"22" : C.gray+"22",
              color: syncStatus==="live" ? C.green : syncStatus==="offline" ? C.red : C.gray,
              borderRadius:99, padding:"4px 10px", fontSize:11, fontWeight:600
            }}>
            {syncStatus==="live" && "🟢 ออนไลน์ ทุกคนเห็นข้อมูลเดียวกัน"}
            {syncStatus==="connecting" && "🔄 กำลังเชื่อมต่อ..."}
            {syncStatus==="offline" && "🔴 ออฟไลน์ (บันทึกไม่ได้ตอนนี้)"}
          </div>
          <button type="button" onClick={()=>setShowReset(true)} style={{ background:C.grayLight, border:"none", borderRadius:99, padding:"4px 10px", fontSize:11, color:C.gray, cursor:"pointer" }}>รีเซ็ต</button>
        </div>
        {showReset && <Confirm msg="ล้างข้อมูลทั้งหมดและกลับค่าเริ่มต้น?" onConfirm={resetAll} onCancel={()=>setShowReset(false)}/>}
      </div>

      {/* Content */}
      <div style={{ padding:"16px 16px 88px" }}>
        {tab==="home" && <Dashboard cat={cat} setCat={setCat} checklist={checklist} setChecklist={setChecklist} weights={weights} setWeights={setWeights}/>}
        {tab==="medical" && <Medical timeline={timeline} setTimeline={setTimeline}/>}
        {tab==="meds" && <Medication meds={meds} setMeds={setMeds}/>}
        {tab==="food" && <FoodWater water={water} setWater={setWater} food={food} setFood={setFood}/>}
        {tab==="expense" && <Expense/>}
        {tab==="hosp" && <HospitalStock hospitals={hospitals} setHospitals={setHospitals} stock={stock} setStock={setStock}/>}
        {tab==="ai" && <AIAssistant cat={cat} water={water} food={food} meds={meds} stock={stock}/>}
      </div>

      {/* Bottom Nav */}
      <div style={{ position:"sticky", bottom:0, width:"100%", background:"rgba(255,255,255,0.97)", backdropFilter:"blur(16px)", borderTop:`1px solid #F3F4F6`, display:"flex", zIndex:100, padding:"6px 0" }}>
        {TABS.map(t=>(
          <button type="button" key={t.id} onClick={()=>setTab(t.id)} style={{ flex:1, background:"none", border:"none", cursor:"pointer", display:"flex", flexDirection:"column", alignItems:"center", gap:2, padding:"4px 0" }}>
            <div style={{ fontSize:tab===t.id?22:19, filter:tab!==t.id?"grayscale(0.5) opacity(0.55)":"none" }}>{t.icon}</div>
            <div style={{ fontSize:9, fontWeight:tab===t.id?700:400, color:tab===t.id?C.orange:C.gray }}>{t.label}</div>
            {tab===t.id && <div style={{ width:18, height:3, borderRadius:99, background:C.orange, marginTop:1 }}/>}
          </button>
        ))}
      </div>
    </div>
  );
}
