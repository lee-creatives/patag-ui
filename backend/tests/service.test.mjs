import test from 'node:test';
import assert from 'node:assert/strict';
import { database, fixtures, ids } from './database.mjs';
import { transaction } from '../db.mjs';
import { bootstrap, reportEvent, getReport, markNotifications, manageTeam, exportReports } from '../service.mjs';
const claims=id=>({sub:id});
test('API contract, server role checks, transactional workflow, idempotency and jurisdiction', async () => {
  const pool=await database(); const {db}=pool;
  try {
    await fixtures(db);
    let snapshot=await transaction(pool,c=>bootstrap(c,{}),claims(ids.local));
    assert.equal(snapshot.reports.length,1); assert.equal(snapshot.reports[0].location.city,'Malolos');
    assert.equal(snapshot.user.role,'admin'); assert.equal(snapshot.demo,false);
    await assert.rejects(transaction(pool,c=>getReport(c,ids.outside),claims(ids.local)),e=>e.status===404);
    await assert.rejects(transaction(pool,c=>reportEvent(c,ids.report,{action:'verify'}),claims(ids.citizen)),e=>e.status===403);
    const key='00000000-0000-4000-8000-000000000099';
    const verified=await transaction(pool,c=>reportEvent(c,ids.report,{action:'verify'},key),claims(ids.local));
    assert.equal(verified.status,'Verified');
    const repeated=await transaction(pool,c=>reportEvent(c,ids.report,{action:'verify'},key),claims(ids.local));
    assert.equal(repeated.status,'Verified');
    await assert.rejects(transaction(pool,c=>reportEvent(c,ids.report,{action:'reject',note:'Different'},key),claims(ids.local)),e=>e.status===409);
    await assert.rejects(transaction(pool,c=>reportEvent(c,ids.report,{action:'assign',teamId:ids.team,priority:'Urgent'}),claims(ids.local)),e=>e.status===400);
    assert.equal((await db.query('SELECT count(*)::integer AS n FROM public.patag_report_history')).rows[0].n,1);
    await transaction(pool,c=>reportEvent(c,ids.report,{action:'assign',teamId:ids.team,priority:'High'}),claims(ids.local));
    await transaction(pool,c=>reportEvent(c,ids.report,{action:'start'}),claims(ids.crew));
    await assert.rejects(transaction(pool,c=>reportEvent(c,ids.report,{action:'resolve'}),claims(ids.crew)),e=>e.status===403);
    snapshot=await transaction(pool,c=>bootstrap(c,{}),claims(ids.local));
    assert.ok(snapshot.notifications.length>0);
    await transaction(pool,c=>markNotifications(c,{id:'all'}),claims(ids.local));
    assert.ok((await transaction(pool,c=>bootstrap(c,{}),claims(ids.local))).notifications.every(n=>n.read));
    await assert.rejects(transaction(pool,c=>manageTeam(c,{id:ids.team,name:'Test Crew',active:false},'PATCH'),claims(ids.local)),e=>e.status===409);
    const result=await transaction(pool,c=>exportReports(c,{ids:[ids.report],fields:['Reference'],format:'CSV'}),claims(ids.local));
    assert.equal(result.reports.length,1);
    await assert.rejects(transaction(pool,c=>exportReports(c,{ids:[ids.outside],fields:['Reference'],format:'CSV'}),claims(ids.local)),e=>e.status===403);
    await assert.rejects(transaction(pool,c=>bootstrap(c,{}),claims(ids.inactive)),e=>e.status===403);
  } finally {await pool.end();}
});
