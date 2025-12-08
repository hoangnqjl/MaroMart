import { Router } from 'express';
import { attributeSuggest } from '../services/attributeSuggest';

const router = Router();


router.post('/attribute-suggestion', attributeSuggest);

export default router;